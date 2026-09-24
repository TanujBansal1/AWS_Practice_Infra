// Injected at deploy time by .github/workflows/frontend.yml (sed-replaces
// the placeholder with the ALB URL from terraform output alb_dns_name).
window.API_BASE_URL = "__API_BASE_URL__";
