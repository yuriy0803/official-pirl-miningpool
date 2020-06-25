## Open Source Mining Pool

### Building on Linux

Dependencies:

  * 64 bit ubuntu
  * NOTE: centos can also work, but some of the commands may be different for the packages
  * go >= 1.10
  * gcc-c++
  * make
  * redis-server >= 2.8.0
  * nodejs >= 4 LTS
  * nginx
  * Pirl geth client
  * recommended to have more then 2 GB of ram, or a swap file set, or compiling may fail. 
  * if you need to make swap, you can run this to add a 3 gig swap file (not usually on openvz vps, it will fail most likely)
 ```
if [ ! -e /swapfile ]
	then
	fallocate -l 3G /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	cp /etc/fstab /etc/fstab.bak
	echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi
```

## note about conventions here, "$" means you are not root, "#" means you are root. ##

### Update installed packages ###
    $ sudo yum update
    or
    $ sudo apt-get update
    $ sudo apt-get -y dist-upgrade

### Install go lang

    $ sudo apt-get install -y build-essential golang-1.10-go unzip git wget curl
    $ sudo ln -s /usr/lib/go-1.10/bin/go /usr/local/bin/go
    or
    $ sudo yum install -y epel-release
    $ sudo yum install -y golang unzip git wget curl
    $ sudo ln -s /usr/lib/go-1.10/bin/go /usr/local/bin/go

### Install redis-server
(easiest to use the packages from the OS vender)

    $ sudo apt-get install -y redis-server
    or
    $ sudo yum install -y redis

It is recommended to bind your DB address on 127.0.0.1 or on internal ip. Also, please set up the password for advanced security!!!

### Install nginx

    $ sudo apt-get install nginx
    or
    $ sudo yum install nginx

sample config located at configs/nginx.default.example (HINT, edit and move to /etc/nginx/sites-available/default)

### Install gcc-c++ and make

    $ sudo apt-get -y install gcc make
    or
    $ sudo yum install gcc make

### Install NODE

This will install the latest nodejs

    $ curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
    $ sudo apt-get install -y nodejs
    or
    $ curl -sL https://rpm.nodesource.com/setup_11.x | sudo -E bash -
    $ sudo yum install -y nodejs

### Install PIRL geth (with PIRL-GUARD) (regular binary, not the masternode binary)
### download from https://git.pirl.io/community/pirl/-/releases/1.9.12-lion

    $ wget https://chaindata.pirl.network/1-9-12-lion/pirl-1-9-12-lion
    $ chmod 0755 pirl-1-9-12-lion
    $ sudo mv pirl-1-9-12-lion /usr/local/bin/pirl-1-9-12-lion

    $ optional: start the binary and sync the chain up.
    $ /usr/local/bin/pirl-1-9-12-lion  (control c when it reaches a blocks=1 each block line)

### Install  Pool

    $ git clone https://git.pirl.io/community/official-pirl-pool.git
    $ cd official-pirl-testnet-pool
    $ make all
    $ ls build/bin/

	you should see the pool binary there.

### Set up pool

presetup configs are in /configs directory, edit to suit your needs

```javascript
{
  // The number of cores of CPU.
  "threads": 2,
  // Prefix for keys in redis store
  "coin": "pirl",
  // Give unique name to each instance
  "name": "main",
  // PPLNS rounds
  "pplns": 9000,

  "proxy": {
    "enabled": true,

    // Bind HTTP mining endpoint to this IP:PORT
    "listen": "0.0.0.0:8888",

    // Allow only this header and body size of HTTP request from miners
    "limitHeadersSize": 1024,
    "limitBodySize": 256,

    /* Set to true if you are behind CloudFlare (not recommended) or behind http-reverse
      proxy to enable IP detection from X-Forwarded-For header.
      Advanced users only. It's tricky to make it right and secure.
    */
    "behindReverseProxy": false,

    // Stratum mining endpoint
    "stratum": {
      "enabled": true,
      // Bind stratum mining socket to this IP:PORT
      "listen": "0.0.0.0:8008",
      "timeout": "120s",
      "maxConn": 8192
    },

    // Try to get new job from geth in this interval
    "blockRefreshInterval": "120ms",
    "stateUpdateInterval": "3s",
    // If there are many rejects because of heavy hash, difficulty should be increased properly.
    "difficulty": 2000000000,

    /* Reply error to miner instead of job if redis is unavailable.
      Should save electricity to miners if pool is sick and they didn't set up failovers.
    */
    "healthCheck": true,
    // Mark pool sick after this number of redis failures.
    "maxFails": 100,
    // TTL for workers stats, usually should be equal to large hashrate window from API section
    "hashrateExpiration": "3h",

    "policy": {
      "workers": 8,
      "resetInterval": "60m",
      "refreshInterval": "1m",

      "banning": {
        "enabled": false,
        /* Name of ipset for banning.
        Check http://ipset.netfilter.org/ documentation.
        */
        "ipset": "blacklist",
        // Remove ban after this amount of time
        "timeout": 1800,
        // Percent of invalid shares from all shares to ban miner
        "invalidPercent": 30,
        // Check after after miner submitted this number of shares
        "checkThreshold": 30,
        // Bad miner after this number of malformed requests
        "malformedLimit": 5
      },
      // Connection rate limit
      "limits": {
        "enabled": false,
        // Number of initial connections
        "limit": 30,
        "grace": "5m",
        // Increase allowed number of connections on each valid share
        "limitJump": 10
      }
    }
  },

  // Provides JSON data for frontend which is static website
  "api": {
    "enabled": true,
    "listen": "0.0.0.0:8080",
    // Collect miners stats (hashrate, ...) in this interval
    "statsCollectInterval": "5s",
    // Purge stale stats interval
    "purgeInterval": "10m",
    // Fast hashrate estimation window for each miner from it's shares
    "hashrateWindow": "30m",
    // Long and precise hashrate from shares, 3h is cool, keep it
    "hashrateLargeWindow": "3h",
    // Collect stats for shares/diff ratio for this number of blocks
    "luckWindow": [64, 128, 256],
    // Max number of payments to display in frontend
    "payments": 50,
    // Max numbers of blocks to display in frontend
    "blocks": 50,
    // Frontend Chart related settings
    "poolCharts":"0 */20 * * * *",
    "poolChartsNum":74,
    "minerCharts":"0 */20 * * * *",
    "minerChartsNum":74

    /* If you are running API node on a different server where this module
      is reading data from redis writeable slave, you must run an api instance with this option enabled in order to purge hashrate stats from main redis node.
      Only redis writeable slave will work properly if you are distributing using redis slaves.
      Very advanced. Usually all modules should share same redis instance.
    */
    "purgeOnly": false
  },

  // Check health of each geth node in this interval
  "upstreamCheckInterval": "5s",

  /* List of geth nodes to poll for new jobs. Pool will try to get work from
    first alive one and check in background for failed to back up.
    Current block template of the pool is always cached in RAM indeed.
  */
  "upstream": [
    {
      "name": "main",
      "url": "http://127.0.0.1:6588",
      "timeout": "10s"
    },
    {
      "name": "backup",
      "url": "http://127.0.0.2:6588",
      "timeout": "10s"
    }
  ],

  // This is standard redis connection options
  "redis": {
    // Where your redis instance is listening for commands
    "endpoint": "127.0.0.1:6379",
    "poolSize": 10,
    "database": 0,
    "password": ""
  },

  // This module periodically remits ether to miners
  "unlocker": {
    "enabled": false,
    // Pool fee percentage
    "poolFee": 1.0,
    // the address is for pool fee. Personal wallet is recommended to prevent from server hacking.
    "poolFeeAddress": "",
    // Amount of donation to a pool maker. 10 percent of pool fee is donated to a pool maker now. If pool fee is 1 percent, 0.1 percent which is 10 percent of pool fee should be donated to a pool maker.
    "donate": true,
    // Unlock only if this number of blocks mined back
    "depth": 120,
    // Simply don't touch this option
    "immatureDepth": 20,
    // Keep mined transaction fees as pool fees
    "keepTxFees": false,
    // Run unlocker in this interval
    "interval": "10m",
    // Geth instance node rpc endpoint for unlocking blocks
    "daemon": "http://127.0.0.1:6588",
    // Rise error if can't reach geth in this amount of time
    "timeout": "10s"
  },

  // Pay out miners using this module
  "payouts": {
    "enabled": true,
    // Require minimum number of peers on node
    "requirePeers": 5,
    // Run payouts in this interval
    "interval": "12h",
    // Geth instance node rpc endpoint for payouts processing
    "daemon": "http://127.0.0.1:6588",
    // Rise error if can't reach geth in this amount of time
    "timeout": "10s",
    // Address with pool coinbase wallet address.
    "address": "0x0",
    // Let geth to determine gas and gasPrice
    "autoGas": true,
    // Gas amount and price for payout tx (advanced users only)
    "gas": "21000",
    "gasPrice": "50000000000",
    // The minimum distribution of mining reward. It is 1 CLO now.
    "threshold": 1000000000,
    // Perform BGSAVE on Redis after successful payouts session
    "bgsave": false
    "concurrentTx": 10
  }
}
```
### install systemd service files
     these are located in configs/systemd_files/
     be sure to edit the ExecStart for your systems paths to the json configs, and the location of the built binary

### Open Firewall

Firewall should be opened to operate this service. Whether Ubuntu firewall is basically opened or not, the firewall should be opened based on your situation.
You can open firewall by opening port TCP:80,443,30303,8002,8004,8008  UDP:30303

## Install Frontend

### Modify configuration file

    $ nano www/config/environment.js

Make some modifications in these settings.

    APP: {
      // API host and port
      ApiUrl: '//testnetpool.pirl.io/',
      PoolName: 'PIRL TESTNET Pool',
      CompanyName: 'PIRL.IO',
      // HTTP mining endpoint
      HttpHost: 'https://testnetpool.pirl.io',
      HttpPort: 8882,

      // Stratum mining endpoint
      StratumHost: 'testnetpool.pirl.io',
      StratumPort: 8002,

      // Fee and payout details
      PoolFee: '0.0%',
      PayoutThreshold: '1.0',
      PayoutInterval: '3h',

      // For network hashrate (change for your favourite fork)
      BlockTime: 13.0,
      BlockReward: 6,
      Unit: 'PIRL',

### Install Frontend
The frontend is a single-page Ember.js application that polls the pool API to render miner stats.

    $ cd official-pirl-testnet-pool/www
    $ sudo npm install -g ember-cli@2.9.1
    $ sudo npm install -g bower
    $ sudo chown -R $USER:$GROUP ~/.npm
    $ sudo chown -R $USER:$GROUP ~/.config
    $ npm install
    $ bower install
    //if your going to run as root, you may need to run " bower install --allow-root "
    $ ./build.sh
    $ note: the build script copies the contents of official-pirl-testnet-pool/www/dist/ to /var/www/


### Install nginx configuration

    $ a sample config file for nginx is include in the configs directory copy it or edit as directed below
    $ sudo nano /etc/nginx/sites-available/default

Modify based on configuration file.

    # Default server configuration
    # nginx example

    upstream api {
        server 127.0.0.1:8080;
    }

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

        location /api {
                proxy_pass http://api;
        }

    }

After setting nginx is completed, run the command below.

    $ sudo service nginx restart

Type your homepage address or IP address on the web.
If you face screen without any issues, pool installation has completed.

### Extra How To Secure the pool frontend with Let's Encrypt (https)

This guide was originally referred from [digitalocean - How To Secure Nginx with Let's Encrypt on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04)

First, install the Certbot's Nginx package with apt-get

```
$ sudo add-apt-repository ppa:certbot/certbot
$ sudo apt-get update
$ sudo apt-get install python-certbot-nginx
```

And then open your nginx setting file, make sure the server name is configured!

```
$ sudo nano /etc/nginx/sites-available/default
. . .
server_name <your-pool-domain>;
. . .
```

Change the _ to your pool domain, and now you can obtain your auto-renewaled ssl certificate for free!

```
$ sudo certbot --nginx -d <your-pool-domain>
```

Now you can access your pool's frontend via https! Share your pool link!

### Notes

* Unlocking and payouts are sequential, 1st tx go, 2nd waiting for 1st to confirm and so on. You can disable that in code. Carefully read `docs/PAYOUTS.md`.
* Also, keep in mind that **unlocking and payouts will halt in case of backend or node RPC errors**. In that case check everything and restart.
* You must restart module if you see errors with the word *suspended*.
* Don't run payouts and unlocker modules as part of mining node. Create separate configs for both, launch independently and make sure you have a single instance of each module running.
* If `poolFeeAddress` is not specified all pool profit will remain on coinbase address. If it specified, make sure to periodically send some dust back required for payments.
* DO NOT OPEN YOUR RPC OR REDIS ON 0.0.0.0!!! It will eventually cause coin theft.

### Credits

Made by sammy007. Licensed under GPLv3.
Modified by Akira Takizawa & The Ellaism Project & phatblinkie and mohannad and the ethpool update project, & PIRL project


### Donations

PIRL or any ethash coin: 0x4bc7b9d69d6454c5666ecad87e5699c1ec02d533


Highly appreciated.
