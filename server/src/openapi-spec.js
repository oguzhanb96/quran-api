/** OpenAPI 3 document for Swagger UI at /docs */
export const openApiSpec = {
  openapi: '3.0.3',
  info: {
    title: 'Quran API',
    description:
      'Knowledge JSON API, alquran.cloud proxy, audio proxy, premium activation.',
    version: '1.0.0',
  },
  servers: [{ url: '/' }],
  tags: [
    { name: 'Health' },
    { name: 'Knowledge' },
    { name: 'Quran' },
    { name: 'Auth' },
    { name: 'Admin' },
  ],
  paths: {
    '/health': {
      get: {
        tags: ['Health'],
        summary: 'Health check',
        responses: { '200': { description: 'OK' } },
      },
    },
    '/api/v1/health': {
      get: {
        tags: ['Health'],
        summary: 'Health check (v1)',
        responses: { '200': { description: 'OK' } },
      },
    },
    '/knowledge/modules': {
      get: {
        tags: ['Knowledge'],
        summary: 'List knowledge modules (catalog)',
        parameters: [
          {
            name: 'lang',
            in: 'query',
            schema: { type: 'string', default: 'tr' },
          },
        ],
        responses: { '200': { description: 'Catalog array' } },
      },
    },
    '/knowledge/{moduleId}': {
      get: {
        tags: ['Knowledge'],
        summary: 'Items for a module',
        parameters: [
          {
            name: 'moduleId',
            in: 'path',
            required: true,
            schema: { type: 'string', example: 'pillars_islam' },
          },
          {
            name: 'lang',
            in: 'query',
            schema: { type: 'string', default: 'tr' },
          },
        ],
        responses: { '200': { description: 'Items array' } },
      },
    },
    '/editions': {
      get: {
        tags: ['Quran'],
        summary: 'Quran editions (alquran.cloud)',
        responses: { '200': { description: 'Editions payload' } },
      },
    },
    '/surah': {
      get: {
        tags: ['Quran'],
        summary: 'All surahs metadata',
        responses: { '200': { description: 'Surah list' } },
      },
    },
    '/surah/{id}': {
      get: {
        tags: ['Quran'],
        summary: 'Surah text by id (edition from lang query)',
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
          {
            name: 'lang',
            in: 'query',
            schema: { type: 'string', default: 'ar' },
          },
        ],
        responses: { '200': { description: 'Surah' } },
      },
    },
    '/surah/{id}/translations': {
      get: {
        tags: ['Quran'],
        summary: 'Surah with translation edition',
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
          {
            name: 'lang',
            in: 'query',
            schema: { type: 'string', default: 'en' },
          },
        ],
        responses: { '200': { description: 'Surah + translation' } },
      },
    },
    '/surah/{surahId}/reciter/{edition}': {
      get: {
        tags: ['Quran'],
        summary: 'Surah ayahs with per-ayah audio URLs',
        parameters: [
          {
            name: 'surahId',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
          },
          {
            name: 'edition',
            in: 'path',
            required: true,
            schema: { type: 'string', example: 'ar.alafasy' },
          },
        ],
        responses: { '200': { description: 'Ayahs with audio' } },
      },
    },
    '/juz/{juzNum}/{edition}': {
      get: {
        tags: ['Quran'],
        summary: 'Juz by number and edition',
        parameters: [
          {
            name: 'juzNum',
            in: 'path',
            required: true,
            schema: { type: 'integer', minimum: 1, maximum: 30 },
          },
          {
            name: 'edition',
            in: 'path',
            required: true,
            schema: { type: 'string', example: 'quran-uthmani' },
          },
        ],
        responses: { '200': { description: 'Juz' } },
      },
    },
    '/audio/{reciter}/{surah}/{ayah}.mp3': {
      get: {
        tags: ['Quran'],
        summary: 'Stream MP3 (proxied)',
        parameters: [
          { name: 'reciter', in: 'path', required: true, schema: { type: 'string' } },
          { name: 'surah', in: 'path', required: true, schema: { type: 'integer' } },
          { name: 'ayah', in: 'path', required: true, schema: { type: 'integer' } },
        ],
        responses: {
          '200': { description: 'audio/mpeg' },
          '404': { description: 'Not found' },
        },
      },
    },
    '/api/v1/auth/premium/activate': {
      post: {
        tags: ['Auth'],
        summary: 'Activate premium (Supabase JWT)',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['plan', 'userId'],
                properties: {
                  plan: { type: 'string' },
                  userId: { type: 'string', format: 'uuid' },
                },
              },
            },
          },
        },
        responses: {
          '200': { description: 'Activated' },
          '401': { description: 'Unauthorized' },
          '503': { description: 'Supabase not configured' },
        },
      },
    },
    '/admin/knowledge/modules': {
      get: {
        tags: ['Admin'],
        summary: 'Catalog + item counts',
        security: [{ adminToken: [] }],
        parameters: [
          {
            name: 'lang',
            in: 'query',
            schema: { type: 'string', default: 'tr' },
          },
        ],
        responses: {
          '200': { description: 'Modules' },
          '401': { description: 'Unauthorized' },
          '503': { description: 'ADMIN_TOKEN not set' },
        },
      },
    },
    '/admin/knowledge/{moduleId}': {
      get: {
        tags: ['Admin'],
        summary: 'Read module items (admin)',
        security: [{ adminToken: [] }],
        parameters: [
          {
            name: 'moduleId',
            in: 'path',
            required: true,
            schema: { type: 'string' },
          },
          {
            name: 'lang',
            in: 'query',
            schema: { type: 'string', default: 'tr' },
          },
        ],
        responses: { '200': { description: 'Items' } },
      },
    },
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
      adminToken: {
        type: 'apiKey',
        in: 'header',
        name: 'X-Admin-Token',
        description: 'Same value as ADMIN_TOKEN env on server',
      },
    },
  },
};
