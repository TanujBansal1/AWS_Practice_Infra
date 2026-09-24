// Injected at deploy time by .github/workflows/frontend.yml. Left empty so
// fetches are relative/same-origin - CloudFront proxies /todos* and /health
// to the ALB (see modules/frontend), avoiding a mixed-content HTTP request
// from this HTTPS site straight to the ALB.
window.API_BASE_URL = "__API_BASE_URL__";
