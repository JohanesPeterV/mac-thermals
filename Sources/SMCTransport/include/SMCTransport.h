#pragma once
#include <stdint.h>

// Read-only AppleSMC transport. Callers serialize access to each connection.
int32_t MBFOpen(uint32_t *connection);
int32_t MBFClose(uint32_t connection);
int32_t MBFRead(uint32_t connection, uint32_t key, uint32_t *type,
                uint8_t bytes[32], uint32_t *size, uint8_t *result, uint8_t *status);
int32_t MBFKeyAtIndex(uint32_t connection, uint32_t index, uint32_t *key,
                      uint8_t *result, uint8_t *status);
int32_t MBFChipName(char bytes[128]);
