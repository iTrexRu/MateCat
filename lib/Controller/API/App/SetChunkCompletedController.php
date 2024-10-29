<?php

namespace API\App;

use AMQHandler;
use API\Commons\KleinController;
use API\Commons\Validators\LoginValidator;
use Chunks_ChunkCompletionEventStruct;
use Comments_CommentDao;
use Comments_CommentStruct;
use Database;
use Email\CommentEmail;
use Email\CommentMentionEmail;
use Email\CommentResolveEmail;
use Exception;
use Features\ProjectCompletion\CompletionEventStruct;
use Features\ProjectCompletion\Model\EventModel;
use INIT;
use InvalidArgumentException;
use Jobs_JobDao;
use Jobs_JobStruct;
use Klein\Response;
use Log;
use RuntimeException;
use Stomp\Transport\Message;
use Teams\MembershipDao;
use Url\JobUrlBuilder;
use Users_UserDao;
use Users_UserStruct;
use Utils;

class SetChunkCompletedController extends KleinController {

    protected function afterConstruct() {
        $this->appendValidator( new LoginValidator( $this ) );
    }

    public function complete(): Response
    {
        try {
            $request = $this->validateTheRequest();

            $struct = new CompletionEventStruct( [
                'uid'               => $this->user->getUid(),
                'remote_ip_address' => Utils::getRealIpAddr(),
                'source'            => Chunks_ChunkCompletionEventStruct::SOURCE_USER,
                'is_review'         => $this->isRevision($request['id_job'], $request['password'])
            ] );

            $model = new EventModel( $request['job'], $struct );
            $model->save();

            return $this->response->json([
                'data' => [
                    'event' => [
                        'id' => (int)$model->getChunkCompletionEventId()
                    ]
                ]
            ]);

        } catch (Exception $exception){
            return $this->returnException($exception);
        }
    }

    /**
     * @return array|\Klein\Response
     * @throws \ReflectionException
     */
    private function validateTheRequest(): array
    {
        $id_job = filter_var( $this->request->param( 'id_job' ), FILTER_SANITIZE_NUMBER_INT );
        $password = filter_var( $this->request->param( 'password' ), FILTER_SANITIZE_STRING, [ 'flags' =>  FILTER_FLAG_STRIP_LOW | FILTER_FLAG_STRIP_HIGH ] );
        $received_password = filter_var( $this->request->param( 'current_password' ), FILTER_SANITIZE_STRING, [ 'flags' =>  FILTER_FLAG_STRIP_LOW | FILTER_FLAG_STRIP_HIGH ] );

        if ( empty( $id_job ) ) {
            throw new InvalidArgumentException("Missing id job", -1);
        }

        if ( empty( $password ) ) {
            throw new InvalidArgumentException( "Missing id password", -2);
        }

        $job = Jobs_JobDao::getByIdAndPassword( $id_job, $password, 60 * 60 * 24 );

        if ( empty( $job ) ) {
            throw new InvalidArgumentException( "wrong password", -10);
        }

        return [
            'id_job' => $id_job,
            'password' => $password,
            'received_password' => $received_password,
            'job' => $job,
        ];
    }
}