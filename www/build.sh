#!/bin/bash

./node_modules/.bin/ember build --environment production
rsync -av dist/* /usr/share/nginx/html/

