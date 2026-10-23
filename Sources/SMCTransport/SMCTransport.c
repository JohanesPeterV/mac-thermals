#include "SMCTransport.h"
#include <IOKit/IOKitLib.h>
#include <stddef.h>
#include <string.h>
#include <sys/sysctl.h>

// REASON: AppleSMC is a reverse-engineered protocol, not a public Apple sensor API.
// The wire layout is shared by open-source SMC clients (see docs/HARDWARE.md).
// Keep the fixed C ABI and pointer lifetimes here; expose no write command.
typedef struct {
    uint32_t key;
    struct { uint8_t major, minor, build, reserved; uint16_t release; } version;
    struct { uint16_t version, length; uint32_t cpu, gpu, memory; } limits;
    struct { uint32_t size, type; uint8_t attributes; } info;
    uint8_t result, status, command;
    uint32_t index;
    uint8_t bytes[32];
} SMCPacket;

_Static_assert(sizeof(SMCPacket) == 80, "Unexpected AppleSMC packet size");
_Static_assert(offsetof(SMCPacket, result) == 40, "Unexpected result offset");
_Static_assert(offsetof(SMCPacket, bytes) == 48, "Unexpected payload offset");

static int32_t call(uint32_t connection, SMCPacket *input, SMCPacket *output) {
    size_t size = sizeof(*output);
    kern_return_t error = IOConnectCallStructMethod(connection, 2, input, sizeof(*input), output, &size);
    if (error != KERN_SUCCESS) return error;
    return size == sizeof(*output) ? KERN_SUCCESS : kIOReturnUnderrun;
}

int32_t MBFOpen(uint32_t *connection) {
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (!service) return kIOReturnNotFound;
    kern_return_t error = IOServiceOpen(service, mach_task_self(), 0, connection);
    IOObjectRelease(service);
    return error;
}

int32_t MBFClose(uint32_t connection) { return IOServiceClose(connection); }

int32_t MBFChipName(char bytes[128]) {
    size_t size = 128;
    int result = sysctlbyname("machdep.cpu.brand_string", bytes, &size, NULL, 0);
    bytes[127] = '\0';
    return result;
}

int32_t MBFRead(uint32_t connection, uint32_t key, uint32_t *type,
                uint8_t bytes[32], uint32_t *size, uint8_t *result, uint8_t *status) {
    SMCPacket input = {0}, output = {0};
    input.key = key;
    input.command = 9; // Key metadata.
    int32_t error = call(connection, &input, &output);
    *result = output.result;
    *status = output.status;
    if (error || *result || *status) return error;
    if (!output.info.size || output.info.size > 32) return kIOReturnBadArgument;
    *type = output.info.type;
    *size = output.info.size;
    input.info.size = *size;
    input.command = 5; // Read bytes.
    memset(&output, 0, sizeof(output));
    error = call(connection, &input, &output);
    *result = output.result;
    *status = output.status;
    if (!error && !*result && !*status) memcpy(bytes, output.bytes, *size);
    return error;
}

int32_t MBFKeyAtIndex(uint32_t connection, uint32_t index, uint32_t *key,
                      uint8_t *result, uint8_t *status) {
    SMCPacket input = {0}, output = {0};
    input.command = 8; // Enumerate keys.
    input.index = index;
    int32_t error = call(connection, &input, &output);
    *result = output.result;
    *status = output.status;
    *key = output.key;
    return error;
}
