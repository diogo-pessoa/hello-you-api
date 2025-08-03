from prometheus_flask_exporter import PrometheusMetrics, Counter, Histogram, Gauge

metrics = None
# Define custom metrics - registered when init_metrics
user_operations = None
request_duration = None
active_users = None
birthday_calculations = None


def init_metrics(app):
    """Initialize metrics for the Flask app"""
    global metrics, user_operations, request_duration, active_users, birthday_calculations

    # Initialize the main metrics exporter
    metrics = PrometheusMetrics(app)

    # Add app info metric
    metrics.info('app_info', 'Application info', version='1.0.0')

    # Initialize custom metrics
    user_operations = Counter('user_operations_total',
                              'Total user operations', ['operation', 'status'])
    request_duration = Histogram('request_duration_seconds',
                                 'Request duration', ['method', 'endpoint'])
    active_users = Gauge('active_users_total',
                         'Total number of users in database')
    birthday_calculations = Counter('birthday_calculations_total',
                                    'Total birthday calculations', ['days_until'])

    return metrics
