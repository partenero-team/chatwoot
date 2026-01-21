import ApiClient from '../ApiClient';

class FormChannel extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }
}

export default new FormChannel();
