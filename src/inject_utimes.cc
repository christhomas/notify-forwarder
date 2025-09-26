#include <sys/time.h>

#include <fcntl.h>
#include <unistd.h>

#include <vector>

#include "inject_utimes.h"

UtimesInjectPlugin::~UtimesInjectPlugin() {}

void UtimesInjectPlugin::inject(const std::vector<std::string>& paths)
{
    for (const auto& path : paths) {
        int fd = open(path.c_str(), O_RDWR | O_CLOEXEC);
        if (fd >= 0) {
            off_t size = lseek(fd, 0, SEEK_END);
            if (size > 0) {
                // Read the first byte and write it back unchanged.
                char byte;
                if (pread(fd, &byte, 1, 0) == 1) {
                    (void)pwrite(fd, &byte, 1, 0);
                }
            }
            else if (size == 0) {
                // File is empty. Temporarily write a byte, then truncate.
                const char placeholder = '\0';
                if (write(fd, &placeholder, 1) == 1) {
                    (void)ftruncate(fd, 0);
                }
            }

            close(fd);
        }

        utimes(path.c_str(), nullptr);
    }
}
