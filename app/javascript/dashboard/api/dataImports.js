/* global axios */
import ApiClient from './ApiClient';

class DataImportsAPI extends ApiClient {
  constructor() {
    super('data_imports', { accountScoped: true });
  }

  get(page = 1) {
    return axios.get(`${this.url}?page=${page}`);
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }
}

export default new DataImportsAPI();
