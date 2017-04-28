'use babel'

import token from './token'

function httpRequest(method, path, body, learnAuth=false) {
  return new Promise((resolve, reject) => {
    var xmlhttp = new XMLHttpRequest();

    xmlhttp.open(method, path);
    xmlhttp.setRequestHeader('Accept', 'application/json');
    xmlhttp.setRequestHeader('Content-Type', 'application/json');
    if (learnAuth) { xmlhttp.setRequestHeader('Authorization', `Bearer ${token.get()}`); }
    xmlhttp.responseType = 'json';

    xmlhttp.addEventListener('load', (e) => resolve(xmlhttp.response, e))
    xmlhttp.addEventListener('error', (e) => reject(xmlhttp.response, e))

    xmlhttp.send(body);
  });
}

export default {
  post(url, body, learnAuth) {
    return httpRequest('POST', url, body, learnAuth)
  },

  patch(url, body, learnAuth) {
    return httpRequest('PATCH', url, body, learnAuth)
  }
}

