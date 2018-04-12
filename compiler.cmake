include(CMakeForceCompiler)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_CROSSCOMPILING 1)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(TARGET_TRIPLET "armv7a-hardfloat-linux-gnueabi")
if(TOOLCHAIN_PREFIX)
else()
    set(TOOLCHAIN_PREFIX "/usr")
endif()

set(TOOLCHAIN_BIN_DIR ${TOOLCHAIN_PREFIX}/bin)
set(CROSS_PREFIX ${TARGET_TRIPLET}-)

if (TOOLCHAIN_COMPILER STREQUAL "clang")
    set(CMAKE_CXX_COMPILER clang++)
else()
    set(CMAKE_CXX_COMPILER ${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-g++)
endif()
set(CMAKE_CXX_LINK_EXECUTABLE "<CMAKE_CXX_COMPILER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> -Wl,--whole-archive <LINK_LIBRARIES> -Wl,--no-whole-archive")

# utilities
set(OBJCOPY ${CROSS_PREFIX}objcopy)
set(OBJDUMP ${CROSS_PREFIX}objdump)
set(SIZE ${CROSS_PREFIX}size)

# setup C++14 required compiler
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED on)
set(CMAKE_CXX_EXTENSIONS OFF)

function (setup_custom_compiler_flags)
    # setup toolchain flags for embedded properties
    set(CXX_FLAGS "-fno-rtti -fno-exceptions -fno-unwind-tables")
    if (TOOLCHAIN_COMPILER STREQUAL "clang")
        set(CXX_FLAGS "${CXX_FLAGS} -target arm-v7m-none-eabi")
    endif()
    set(COMMON_FLAGS "-g -mlittle-endian -mthumb -nostdlib -nostdinc -DTHUMB -fno-common -no-pie -fno-pic")
    set(WARN_FLAGS "-Wall -Wextra")
    set(OPTIMIZE_FLAGS "-ffreestanding -fomit-frame-pointer")

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS} ${WARN_FLAGS} ${OPTIMIZE_FLAGS} ${CPU_FLAGS} ${CXX_FLAGS}" CACHE INTERNAL "cxx compiler flags")
endfunction()

function (setup_custom_linker_flags LINKER_SCRIPT TARGET)
    set(CMAKE_CXX_LINK_FLAGS "-Wl,-T${LINKER_SCRIPT} -Wl,-Map,${TARGET}.map -nostartfiles" CACHE INTERNAL "cxx linker flags")
endfunction()

if(ST_UTILS_PATH)
else()
    set(ST_UTILS_PATH /home/nis/old_frame/stm32/stlink)
endif()
set(ST_FLASH ${ST_UTILS_PATH}/st-flash)

function (setup_custom_target_properties TARGET)
    set(BIN_FILE ${TARGET}.bin)

    add_custom_command(TARGET ${TARGET} POST_BUILD
        COMMAND ${OBJCOPY} -Obinary $<TARGET_FILE:${TARGET}> ${CMAKE_BINARY_DIR}/${BIN_FILE}
        COMMENT "BUILDING ${BIN_FILE}"
        COMMAND ${OBJDUMP} -DS $<TARGET_FILE:${TARGET}> > ${TARGET}.dis
        COMMENT "CREATING ${TARGET}.dis"
        COMMAND ${SIZE} $<TARGET_FILE:${TARGET}>
    )

    add_custom_target(write DEPENDS ${CMAKE_BINARY_DIR}/${TARGET}.bin COMMAND ${ST_FLASH} --reset write ${CMAKE_BINARY_DIR}/${TARGET}.bin 0x8000000)
endfunction()
