#ifndef PLATFORM_UTILS_H
#define PLATFORM_UTILS_H

#if !defined(__clang__) && !defined(__GNUC__)
#define __unused
#elif !defined(__unused)
#define __unused __attribute__((unused))
#endif

#endif /* PLATFORM_UTILS_H */
