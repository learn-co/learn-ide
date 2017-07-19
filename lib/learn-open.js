'use babel'

import localStorage from './local-storage'

let openPath = localStorage.get('learnOpenLabOnActivation');
localStorage.delete('learnOpenLabOnActivation');

export default {
  getLabSlug () {
    return openPath || null
  }
}