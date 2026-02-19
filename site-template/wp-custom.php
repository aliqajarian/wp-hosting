<?php
/**
 * Custom WordPress Settings
 * This file is managed by the WP-HOSTING system.
 */

/* Force HTTPS for Reverse Proxy */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
    $_SERVER['HTTPS'] = 'on';
}

/* File System Method (Optimize for Syncthing) */
define('FS_METHOD', 'direct');

/* Resource Limits */
define('WP_MEMORY_LIMIT', '512M');
@set_time_limit(300);

/* Redis Configuration (Object Cache) */
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);

/* Security: Disable File Editor */
define('DISALLOW_FILE_EDIT', true);
