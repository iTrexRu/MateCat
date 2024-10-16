<?php

namespace API\App;

use API\Commons\KleinController;
use API\Commons\Validators\LoginValidator;
use CatUtils;
use Chunks_ChunkDao;
use Constants_TranslationStatus;
use Database;
use Exception;
use Exceptions\NotFoundException;
use Features;
use Features\ReviewExtended\BatchReviewProcessor;
use Features\ReviewExtended\ReviewUtils;
use Features\TranslationEvents\Model\TranslationEvent;
use Features\TranslationEvents\TranslationEventsHandler;
use InvalidArgumentException;
use Jobs_JobDao;
use Log;
use Matecat\SubFiltering\MateCatFilter;
use RuntimeException;
use Translations_SegmentTranslationDao;
use TranslationsSplit_SplitDAO;
use TranslationsSplit_SplitStruct;
use WordCount\CounterModel;

class SplitSegmentController extends KleinController {

    protected function afterConstruct() {
        $this->appendValidator( new LoginValidator( $this ) );
    }

    public function split()
    {
        try {
            $data = $this->validateTheRequest();

            $translationStruct = TranslationsSplit_SplitStruct::getStruct();
            $translationStruct->id_segment = $data['id_segment'];
            $translationStruct->id_job     = $data['id_job'];

            $featureSet = $this->getFeatureSet();

            /** @var MateCatFilter $Filter */
            $Filter = MateCatFilter::getInstance( $featureSet, $data['jobStruct']->source, $data['jobStruct']->target, [] );
            list( $data['segment'], $translationStruct->source_chunk_lengths ) = CatUtils::parseSegmentSplit( $data['segment'], '', $Filter );

            /* Fill the statuses with DEFAULT DRAFT VALUES */
            $pieces                                  = ( count( $translationStruct->source_chunk_lengths ) > 1 ? count( $translationStruct->source_chunk_lengths ) - 1 : 1 );
            $translationStruct->target_chunk_lengths = [
                'len'      => [ 0 ],
                'statuses' => array_fill( 0, $pieces, Constants_TranslationStatus::STATUS_DRAFT )
            ];

            $translationDao = new TranslationsSplit_SplitDAO( Database::obtain() );
            $result         = $translationDao->atomicUpdate( $translationStruct );

            if ( $result instanceof TranslationsSplit_SplitStruct ) {
                return $this->response->json([
                    'data' => 'OK',
                    'errors' => [],
                ]);
            }

            Log::doJsonLog( "Failed while splitting/merging segment." );
            Log::doJsonLog( $translationStruct );
            throw new RuntimeException("Failed while splitting/merging segment.");

        } catch (Exception $exception){
            return $this->returnException($exception);
        }
    }

    /**
     * @return array
     * @throws \Exceptions\NotFoundException
     */
    private function validateTheRequest()
    {
        $id_job = filter_var( $this->request->param( 'id_job' ), FILTER_SANITIZE_NUMBER_INT );
        $id_segment = filter_var( $this->request->param( 'id_segment' ), FILTER_SANITIZE_NUMBER_INT );
        $password = filter_var( $this->request->param( 'password' ), FILTER_SANITIZE_STRING, [ 'flags' =>  FILTER_FLAG_STRIP_LOW | FILTER_FLAG_STRIP_HIGH ] );
        $segment = filter_var( $this->request->param( 'segment' ), FILTER_UNSAFE_RAW );
        $target = filter_var( $this->request->param( 'target' ), FILTER_UNSAFE_RAW );
        $exec = filter_var( $this->request->param( 'exec' ), FILTER_SANITIZE_STRING, [ 'flags' =>  FILTER_FLAG_STRIP_LOW | FILTER_FLAG_STRIP_HIGH ] );

        if ( empty( $id_job ) ) {
            throw new InvalidArgumentException("Missing id_job", -3);
        }

        if ( empty( $id_segment ) ) {
            throw new InvalidArgumentException("Missing id_segment", -4);
        }

        if ( empty( $password ) ) {
            throw new InvalidArgumentException("Missing jobp password", -5);
        }

        // this checks that the json is valid, but not its content
        if ( is_null( $segment ) ) {
            throw new InvalidArgumentException("Invalid source_chunk_lengths json", -6);
        }

        // check Job password
        $jobStruct = Chunks_ChunkDao::getByIdAndPassword( $id_job, $password );

        if ( is_null( $jobStruct ) ) {
            throw new NotFoundException("Job not found");
        }

        $this->featureSet->loadForProject( $jobStruct->getProject() );

        return [
            'id_job' => $id_job,
            'id_segment' => $id_segment,
            'job_pass' => $password,
            'segment' => $segment,
            'target' => $target,
            'exec' => $exec,
        ];
    }
}
