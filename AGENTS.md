# Ouroboros - Agent Documentation

## What It Does

Ouroboros is an automated Docker container update agent that monitors running containers and automatically updates them to the latest available images from their registries. It preserves all container configuration (volumes, networks, environment variables, restart policies, etc.) during updates.

## Core Functionality

### Primary Purpose
- **Automated Updates**: Monitors Docker containers and updates them when new images are available
- **Zero-Downtime Philosophy**: Recreates containers with identical configuration to maintain service continuity
- **Self-Update Capability**: Can update itself without manual intervention
- **Multi-Mode Support**: Works with both standard Docker containers and Docker Swarm services

## Architecture Overview

### Main Components

1. **`ouroboros.py`** - Entry point and scheduler
   - Parses CLI arguments and environment variables
   - Sets up APScheduler for interval or cron-based execution
   - Manages Docker socket connections
   - Coordinates update cycles

2. **`dockerclient.py`** - Docker API interaction
   - `Docker` class: Manages Docker client connections (supports TLS)
   - `Container` class: Handles standard container updates
   - `Service` class: Handles Docker Swarm service updates
   - Image pulling, container recreation, network management

3. **`config.py`** - Configuration management
   - Merges environment variables and CLI arguments
   - Validates configuration
   - Filters sensitive data from logs

4. **`notifiers.py`** - Notification system
   - Uses Apprise library for multi-platform notifications
   - Supports Discord, Slack, Email, Telegram, and many more
   - Sends startup, update, and monitor-only notifications

5. **`dataexporters.py`** - Metrics export
   - Prometheus exporter (HTTP endpoint)
   - InfluxDB client
   - Tracks container update counts and monitoring stats

6. **`helpers.py`** - Utility functions
   - Container property preservation
   - Hook system execution
   - Image digest handling

## How It Works

### Update Cycle Flow

1. **Initialization**
   - Connects to Docker socket(s) (Unix or TCP, with optional TLS)
   - Loads configuration from environment variables and CLI args
   - Sets up scheduler (interval-based or cron)
   - Initializes notification and metrics systems

2. **Container Discovery**
   - Lists running containers (excludes itself unless self-update enabled)
   - Filters based on:
     - `--monitor` list (specific containers)
     - `--ignore` list (excluded containers)
     - `com.ouroboros.enable` label (if label monitoring enabled)
     - `--labels-only` mode (only containers with labels)

3. **Update Detection**
   - For each monitored container:
     - Gets current image tag and digest
     - Pulls latest image from registry (with auth if configured)
     - Compares image IDs/digests
     - If different, marks container for update

4. **Dependency Handling**
   - Checks for `com.ouroboros.depends_on` label (soft dependency)
   - Checks for `com.ouroboros.hard_depends_on` label (hard dependency)
   - Stops dependent containers before updating parent
   - Recreates hard dependencies after update

5. **Container Recreation**
   - Stops old container (with custom signal if `com.ouroboros.stop_signal` label set)
   - Removes old container
   - Creates new container with:
     - Same name, hostname, user, working directory
     - Same volumes, ports, environment variables
     - Same entrypoint, command, labels
     - Same restart policy, network configuration
     - Same healthcheck configuration
   - Reconnects to all networks from old container
   - Starts new container

6. **Cleanup**
   - Optionally removes old images (`--cleanup`)
   - Optionally prunes unused volumes (`--cleanup-unused-volumes`)

7. **Notifications & Metrics**
   - Sends update notifications via Apprise
   - Updates Prometheus/InfluxDB metrics
   - Executes hooks at various stages

### Scheduling

- **Interval Mode**: Checks every N seconds (default: 300)
- **Cron Mode**: Uses cron syntax for scheduled checks
- **Run Once**: Single execution mode (useful with `--dry-run`)

### Self-Update Mechanism

When `--self-update` is enabled:
- Ouroboros can update itself
- Creates new container named `ouroboros-updated`
- Starts new instance
- Old instance stops and removes itself after 30 seconds
- Preserves metrics counters across updates

### Docker Swarm Mode

When `--swarm` is enabled:
- Monitors Docker Swarm services instead of containers
- Uses service labels (`com.ouroboros.enable`)
- Updates services via `service.update()` with new image digest
- Compares SHA256 digests instead of image IDs

## Key Features

### Filtering & Selection
- Monitor specific containers: `--monitor container1 container2`
- Ignore containers: `--ignore container1 container2`
- Label-based monitoring: `--label-enable` + `com.ouroboros.enable=true`
- Labels-only mode: `--labels-only` (strict compliance)

### Update Behavior
- **Tag Preservation**: Updates to same tag by default
- **Latest Only**: `--latest-only` forces updates to `:latest` tag
- **Dry Run**: `--dry-run` shows what would be updated without making changes
- **Monitor Only**: `--monitor-only` sends notifications but doesn't update

### Notifications
- Multi-platform via Apprise (Discord, Slack, Email, Telegram, etc.)
- Startup notifications (can be disabled)
- Update notifications with container details
- Monitor-only notifications for available updates

### Metrics
- **Prometheus**: HTTP endpoint on configurable address/port
- **InfluxDB**: Writes update counts and monitoring stats
- Tracks: containers monitored, total updated, per-container counts

### Hooks System
- Executes Python scripts from `hooks/{hookname}/` directories
- Available hooks:
  - `updates_enumerated`: Before processing updates
  - `before_update`: Before container recreation
  - `after_update`: After container recreation
  - `before_image_cleanup`: Before removing old images
  - `before_stop_depends_container`: Before stopping dependencies
  - `before_start_depends_container`: Before starting dependencies
  - `before_recreate_hard_depends_container`: Before recreating hard dependencies
  - `after_recreate_hard_depends_container`: After recreating hard dependencies
  - `before_self_update`: Before self-update
  - `after_self_update`: After self-update
  - `before_self_cleanup`: Before cleaning up old self
  - `after_self_cleanup`: After cleaning up old self
  - `dry_run_update`: During dry-run mode
  - `notify_update`: During monitor-only mode

### Security
- Docker TLS support with certificate verification
- Private registry authentication
- Sensitive data filtering in logs
- Network isolation support

## Configuration Methods

1. **Environment Variables**: All options can be set via `UPPERCASE` env vars
2. **CLI Arguments**: Command-line flags override defaults
3. **Precedence**: CLI args > Environment vars > Defaults

## Dependencies

- `docker` (>=4.3.1): Docker API client
- `apscheduler` (>=3.6.3): Job scheduling
- `apprise` (>=0.8.9): Multi-platform notifications
- `prometheus_client` (>=0.8.0): Metrics export
- `influxdb` (>=5.3.1): InfluxDB client
- `Babel` (>=2.9.1): Internationalization
- `pytz`: Timezone support

## Deployment

- **Docker**: Runs as a container with Docker socket mounted
- **Multi-arch**: Supports amd64, arm64, arm/v7
- **Standalone**: Can be installed via pip and run directly

## Use Cases

1. **Automated CI/CD**: Push new images, Ouroboros deploys automatically
2. **Multi-host Management**: Monitor containers across multiple Docker hosts
3. **Production Updates**: Scheduled updates during maintenance windows (cron)
4. **Development**: Quick iteration with short intervals
5. **Compliance**: Label-based monitoring for strict update policies

