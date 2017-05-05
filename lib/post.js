'use babel'

function httpRequest(method, path, body, headers={}) {
  return new Promise((resolve, reject) => {
    var xmlhttp = new XMLHttpRequest();

    xmlhttp.open(method, path);
    xmlhttp.responseType = 'json';

    xmlhttp.setRequestHeader('Accept', 'application/json');
    xmlhttp.setRequestHeader('Content-Type', 'application/json');

    Object.keys(headers).forEach((key) => {
      xmlhttp.setRequestHeader(key, headers[key]);
    });

    xmlhttp.addEventListener('load', (e) => resolve(xmlhttp.response, e))
    xmlhttp.addEventListener('error', (e) => reject(xmlhttp.response, e))

    xmlhttp.send(JSON.stringify(body));
  });
}

export default function post(url, body, headers) {
  return httpRequest('POST', url, body, headers)
}

