# Changelog

## 0.6.0
### Added
- Instrumentation (for tracking metrics using statsd or other tools)
- Message ID and produced at timestamp to consumer logs

### Changed
- Bunny gem dependency to `~> 2.2`
- Reset reconnect attempts back to zero if message is successfully published

## 0.5.0
### Added
- Configuration options: `max_reconnect_attempts` and `network_recovery_interval`
- Reconnect handling on closed connections in producer

## 0.4.0
### Added
- Configuration option: `heartbeat_interval`

### Changed
- Configuration values: replaced single AMQP string with individual config options (eg. host, port etc...)

### Removed
- Configuration option: `queue_namespace` as RabbitMQ native VHOST can be used instead

## 0.3.0
### Added
- Message ID to payload
- Produced at timestamp to payload
- Improved documentation

## 0.2.0
### Added
- Configuration option: `queue_namespace` to namespace queue names when
producing and consuming messages

## 0.1.0
### Added
- Initial project release
