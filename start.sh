#!/bin/bash
exec node dist/index.js gateway --bind lan --port ${PORT:-18789}
