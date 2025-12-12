import ApiClient from './ApiClient';

class PipelineStagesApi extends ApiClient {
  constructor() {
    super('pipeline_stages', { accountScoped: true });
  }

  reorder(ordering) {
    return this.client.post(`${this.url}/reorder`, { ordering });
  }
}

export default new PipelineStagesApi();
