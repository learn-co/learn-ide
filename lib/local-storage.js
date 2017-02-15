module.exports = {
  get(key) {
    return localStorage.getItem(key)
  },
  set(key, value) {
    localStorage.setItem(key, value)
  },
  delete(key) {
    localStorage.removeItem(key)
  },
  remove(key) {
    var item = localStorage.getItem(key)
    localStorage.removeItem(key)
    return item
  }
}
