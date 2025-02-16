#!/bin/bash

SCRIPT_DIR=$(dirname $0)

sudo -u postgres psql -f "$SCRIPT_DIR/create-postgres-user.sql"
