export function buildOpenApiSpec() {
  const spec: any = {
    openapi: '3.1.0',
    info: {
      title: 'ArchieOS Operations API',
      version: '1.0.0',
      description: 'OpenAPI 3.1 specification for Operations Center APIs',
    },
    servers: [{ url: 'http://localhost:3000' }],
    paths: {
      
      '/v1/operations/listings': {
        get: {
          summary: 'List listings',
          operationId: 'listListings',
          parameters: [
            {
              name: 'includeDeleted',
              in: 'query',
              required: false,
              schema: { type: 'boolean' },
              description: 'Include soft-deleted listings (marked with deletedAt timestamp). Default: false'
            },
            {
              name: 'status',
              in: 'query',
              required: false,
              schema: { type: 'string', enum: ['new', 'in_progress', 'completed'] },
              description: 'Filter by listing status'
            },
            {
              name: 'page',
              in: 'query',
              required: false,
              schema: { type: 'number', minimum: 1 },
              description: 'Page number for pagination'
            },
            {
              name: 'limit',
              in: 'query',
              required: false,
              schema: { type: 'number', minimum: 1, maximum: 100 },
              description: 'Number of results per page (max 100)'
            },
            {
              name: 'sortBy',
              in: 'query',
              required: false,
              schema: { type: 'string', enum: ['created_at', 'due_date', 'address'] },
              description: 'Sort results by field'
            }
          ],
          responses: { '200': { description: 'OK' } }
        },
      },
      '/v1/operations/listings/{id}': {
        get: {
          summary: 'Get listing by id',
          operationId: 'getListingById',
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { '200': { description: 'OK' }, '404': { description: 'Not Found' } },
        },
      },
      '/v1/operations/listings/{id}/details': {
        get: {
          summary: 'Get listing details',
          operationId: 'getListingDetails',
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { '200': { description: 'OK' }, '404': { description: 'Not Found' } },
        },
      },
      '/v1/operations/listings/{id}/restore': {
        post: {
          summary: 'Restore a soft-deleted listing',
          operationId: 'restoreListing',
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' }, description: 'Listing ID to restore' }],
          responses: {
            '200': {
              description: 'Listing restored successfully',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      success: { type: 'boolean' },
                      restoredTasksCount: { type: 'number' }
                    }
                  }
                }
              }
            },
            '400': { description: 'Listing is not deleted' },
            '404': { description: 'Not Found' },
            '403': { description: 'Forbidden' }
          },
        },
      },
      '/v1/operations/queues': {
        get: { summary: 'Queue summary', operationId: 'getQueues', responses: { '200': { description: 'OK' } } },
      },
      '/v1/operations/queue': {
        get: { summary: 'Queue detail', operationId: 'getQueue', responses: { '200': { description: 'OK' } } },
      },
      '/v1/operations/tasks/{listingId}': {
        get: {
          summary: 'List tasks for a listing',
          operationId: 'listListingTasks',
          parameters: [{ name: 'listingId', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { '200': { description: 'OK' } },
        },
      },
      // Implemented path variant in code
      '/v1/operations/tasks/task/{taskId}': {
        get: {
          summary: 'Get task by id (variant)',
          operationId: 'getTaskByIdVariant',
          parameters: [{ name: 'taskId', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { '200': { description: 'OK' }, '404': { description: 'Not Found' } },
        },
      },
      
      '/v1/operations/tasks/{taskId}/claim': {
        post: {
          summary: 'Claim task',
          operationId: 'claimTask',
          parameters: [{ name: 'taskId', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: { userId: { type: 'string' }, assigneeId: { type: 'string' }, notes: { }, },
                },
              },
            },
          },
          responses: { '200': { description: 'OK' } },
        },
      },
      '/v1/operations/tasks/{taskId}/unclaim': {
        post: {
          summary: 'Unclaim task', operationId: 'unclaimTask',
          parameters: [{ name: 'taskId', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { '200': { description: 'OK' } },
        },
      },
      '/v1/operations/tasks/{taskId}/complete': {
        post: {
          summary: 'Complete task', operationId: 'completeTask',
          parameters: [{ name: 'taskId', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: {
            required: false,
            content: { 'application/json': { schema: { type: 'object', properties: { userId: { type: 'string' }, completedBy: { type: 'string' }, outputs: { } } } } },
          },
          responses: { '200': { description: 'OK' } },
        },
      },
      '/v1/operations/tasks/{taskId}/reopen': {
        post: {
          summary: 'Reopen task', operationId: 'reopenTask',
          parameters: [{ name: 'taskId', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: { required: false, content: { 'application/json': { schema: { type: 'object', properties: { assigneeId: { type: 'string' } } } } } },
          responses: { '200': { description: 'OK' } },
        },
      },
      '/v1/operations/my-tasks': {
        get: { summary: 'My tasks', operationId: 'getMyTasks', responses: { '200': { description: 'OK' } } },
      },
      '/v1/operations/stray-queues': {
        get: { summary: 'Stray queues', operationId: 'getStrayQueues', responses: { '200': { description: 'OK' } } },
      },
      '/v1/operations/board': {
        get: { summary: 'Board view', operationId: 'getBoard', responses: { '200': { description: 'OK' } } },
      },
      '/files/sign-get': {
        post: {
          summary: 'Sign S3 GET for downloads',
          operationId: 'signGetFile',
          requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { objectKey: { type: 'string' } }, required: ['objectKey'] } } } },
          responses: { '200': { description: 'OK' } },
        },
      },
      '/v1/listings/{id}/documents': {
        get: {
          summary: 'List listing documents',
          operationId: 'listListingDocuments',
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { '200': { description: 'OK' }, '404': { description: 'Not Found' } },
        },
      },
      '/v1/tasks/{taskId}/notes': {
        post: {
          summary: 'Add a note to a task',
          operationId: 'addTaskNote',
          parameters: [{ name: 'taskId', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { text: { type: 'string' } }, required: ['text'] } } } },
          responses: { '200': { description: 'OK' } },
        },
        get: {
          summary: 'List task notes',
          operationId: 'listTaskNotes',
          parameters: [{ name: 'taskId', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { '200': { description: 'OK' } },
        },
      },
      '/entities/me': {
        get: { summary: 'Get current entity', operationId: 'getMe', responses: { '200': { description: 'OK' } } },
      },
      '/entities/{id}': {
        get: {
          summary: 'Get entity by id', operationId: 'getEntity',
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { '200': { description: 'OK' }, '404': { description: 'Not Found' } },
        },
      },
      '/entities': {
        get: {
          summary: 'Search entities by type and name',
          operationId: 'searchEntities',
          parameters: [
            { name: 'type', in: 'query', required: true, schema: { type: 'string' } },
            { name: 'query', in: 'query', required: false, schema: { type: 'string' } },
          ],
          responses: { '200': { description: 'OK' } },
        },
      },
      // Auth
      '/auth/me': {
        get: { summary: 'Current session user', operationId: 'getAuthMe', responses: { '200': { description: 'OK' }, '401': { description: 'Unauthorized' } } },
      },
      '/auth/link/slack': {
        post: {
          summary: 'Link Slack to current user', operationId: 'linkSlack',
          requestBody: { required: true, content: { 'application/json': { schema: { type: 'object', properties: { code: { type: 'string' }, redirectUri: { type: 'string' } }, required: ['code'] } } } },
          responses: { '200': { description: 'OK' }, '401': { description: 'Unauthorized' } },
        },
      },
      '/slack/events': {
        post: {
          summary: 'Slack Events webhook',
          operationId: 'slackEvents',
          parameters: [
            { name: 'X-Slack-Signature', in: 'header', required: true, schema: { type: 'string' } },
            { name: 'X-Slack-Request-Timestamp', in: 'header', required: true, schema: { type: 'string' } },
          ],
          description: 'Accepts Slack Events API payloads. Respond within 3 seconds; Slack will retry on slower or non-2xx responses.',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    type: { type: 'string', enum: ['event_callback', 'url_verification'] },
                    challenge: { type: 'string', description: 'Provided during url_verification handshake.' },
                    event: { type: 'object' },
                    event_id: { type: 'string' },
                    event_time: { type: 'number' },
                  },
                  required: ['type'],
                },
              },
            },
          },
          security: [{ slackSignature: [] }],
          responses: { '200': { description: 'OK' }, '401': { description: 'Invalid signature' } },
        },
      },
      '/slack/interact': {
        post: {
          summary: 'Slack Interactivity webhook',
          operationId: 'slackInteract',
          parameters: [
            { name: 'X-Slack-Signature', in: 'header', required: true, schema: { type: 'string' } },
            { name: 'X-Slack-Request-Timestamp', in: 'header', required: true, schema: { type: 'string' } },
          ],
          requestBody: {
            required: true,
            content: {
              'application/x-www-form-urlencoded': {
                schema: {
                  type: 'object',
                  properties: {
                    payload: {
                      type: 'string',
                      description: 'JSON-encoded interactive payload'
                    }
                  },
                  required: ['payload']
                }
              }
            }
          },
          security: [{ slackSignature: [] }],
          responses: {
            '200': { description: 'OK' },
            '401': { description: 'Invalid signature' }
          },
        },
      },
      // Admin (dev-only)
      '/admin/seed-tasks': {
        post: { summary: 'Seed tasks for a listing (dev)', operationId: 'adminSeedTasks', responses: { '200': { description: 'OK' }, '403': { description: 'Forbidden' } } },
      },
      '/admin/tasks/purge-seeded': {
        post: { summary: 'Purge seeded tasks (dev)', operationId: 'adminPurgeSeeded', responses: { '200': { description: 'OK' }, '403': { description: 'Forbidden' } } },
      },
      '/admin/tasks/mock': {
        post: { summary: 'Generate mock tasks (dev)', operationId: 'adminMockTasks', responses: { '200': { description: 'OK' }, '403': { description: 'Forbidden' } } },
      },
      '/admin/people/upsert': {
        post: { summary: 'Upsert people (dev)', operationId: 'adminUpsertPeople', responses: { '200': { description: 'OK' }, '403': { description: 'Forbidden' } } },
      },
      // Debug
      '/whoami': {
        get: { summary: 'Debug: return authenticated user (dev)', operationId: 'whoami', responses: { '200': { description: 'OK' } } },
      },
    },
  };
  return spec;
}
