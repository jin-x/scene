# Para\\\\e/ API functions



## API function calls

API functions are called by `call dword [ebp+fn]` (3-byte instruction, where **fn** is function number) or by `call ebp` (2-byte instruction) with function number in `al`. Value in `ebp` is set on intro start and it's not recommended to modify it (however, it is not prohibited). If you have modified value of `ebp` you can use respectively `call dword [API_TABLE_BASE+fn]` (6-byte instruction) or `call API_TABLE_BASE` (`call API_HANDLER` is alias). Parameters for *general functions* (with negative and zero numbers) are passed in stack from right to left (i.e. starting to push the last parameter, finishing to push the 1st parameter; according to `stdcall` calling convention). Result is returned in `eax` register and/or carry flag (`cf`). All other registers are not modified, flags can be modified. Calling ABI of *extended functions* (with positive numbers) may differ and will be described in corresponding section.

Note that when you are using call with function number in `al` then value in `al` will be sign-extended to `eax` before function call!

For the best comfort use `apicall` macro with function number/name or `al` as parameter to call API function via `ebp` register. Use `dircall` macro (or its alias `apicall_direct`) with function number/name or `al` in the 1st parameter to call API function via `API_TABLE_BASE`. Function number can be placed in 32-bit register and this register can be specified as the 1st macro parameter. API function parameters can be passed via comma after function number/name.

Examples:

- `apicall @ThreadCall, func_addr` will be translated to `push func_addr` and `call dword [ebp+0x10]` (5 + 3 bytes).
- `apicall al` will be translated to `call ebp` (2 bytes).
- `dircall ebx` will be translated to `call dword [API_TABLE_BASE+ebx]` (6 bytes).
- `dircall al` will be translated to `call API_TABLE_BASE` (5 bytes).



## Intro startup

Intro starts at `CODE_ADDRESS` (0x10000000) with the following register values:

- All arithmetic flags (`cf`, `zf`, `pf`, `sf`, `of`, `af`) and `df` are reset.
- `eax` = 0.
- `ebx` = CPU feature bit set.
- `ecx` = code size.
- `edx` = screen info (if specified in header) or 0 for console mode.
- `esi` = intro code start address (`0x10000000 = ebp*2`).
- `edi` = frame buffer address (if `edx != 0`) or code end address for console mode.
- `ebp` = API function table / handler (`0x08000000`).



## General functions

###### Function groups

- **0…0x0F** — control, memory and miscellaneous functions
- **0x10…0x1F** — threading functions;
- **0x20…0x2F** — video functions;
- **0x30…0x3F** — sound functions;
- **0x40…0x4F** — date/time and keyboard/mouse functions;
- **0x50…0x5F** — console functions;
- **0x60…0x6F** — file functions;
- **0x70…0x7F** — reserved (for future extra functions).



## Control, memoryControl, memory and miscellaneous functions

#### #0 `@Exit()` — exit intro.

The same as `ret` instruction from the main thread.

###### Never returns.



##### #1 — invalid function number (can't be used).



##### #2 @Abort(code) — abort intro execution.

Exit with critical error.

###### Parameters:

1. **code** — abort code (`ABORT_CODE_*`); if code is > 255 then 0 value (`ABORT_CODE_UNKNOWN`) is used.

###### Never returns.



##### #3 @SetGeneralOptions(options) — set general options.

<u>Parameters:</u>

1. **options** — option bit set:
   - bit 0: time-dependence (0 — intro is not time-dependent (rewind/speed change is unavailable if special options is not specified); 1 — intro is time-dependent (rewind/speed change is available)) [default is 0].
   - bits 1…2: 0,1 — launch in full-screen mode by default (if required mode is not available: 0 — resize to desktop screen size [default], 1 — use windowed mode with large pixels); 2,3 — launch in windowed mode by default (2— with small pixels, 3 — with large pixels). *Can't be changed if corresponding command line option is specified.*
   - bit 3: resize method (0 — nearest pixels, 1 — linear interpolation) [default is 0]. *Can't be changed if corresponding command line option is specified.*
   - bit 4: frame buffer alignment mode (0 — don't align frame buffer; 1 — align frame buffer to 16 MB address boundary) [default is 1].
   - bits 5…6: line alignment mode (0 — 4-byte alignment; 1 — 64-byte alignment; 2 — alignment by 256 pixels; 3 — line width is a power of 2 (but not less than 4 bytes)) [default is 0].
   - bit 7: exception mode on critical API errors (0 — disabled, return error result; 1 — enabled, generate exception) [default is 1].
   - bit 8: exception mode on common API errors (0 — disabled, return error result; 1 — enabled, generate exception) [default is 0].

<u>Returns:</u>

- `eax` = old option bit set.

###### #4 @MemoryAllocate(size) — allocate memory in heap.

<u>Parameters:</u>

1. Memory size in bytes.

<u>Returns:</u>

- `cf`: 0 — success, 1 — memory allocation error *(only if exception mode is disabled, else exception is generated).*
- `eax` = pointer to allocated memory block (only if `cf` is reset). Memory is zeroed.

###### #5 @MemoryFree(pointer) — free memory in heap.

<u>Parameters:</u>

1. Pointer to allocated memory block.

<u>Returns:</u>

- `cf`: 0 — success, 1 — memory deallocation error *(only if exception mode is disabled, else exception is generated).*

- **0x0E** (`@WriteDebugLog`) — write to debugging log.

  <u>Parameters:</u>

  1. Log information bit set:

     - bit 0: general purpose registers.
     - bit 1: flags.
     - bit 2: FPU registers.
     - bit 3: FPU control, status and tag words.
     - bit 4: MMX registers.
     - bits 5…6: other SIMD registers (0 — nothing, 1 — XMM registers, 2 — YMM registers, 3 — ZMM registers).
     - bits 7…8: SIMD element type (0 — real, 1 — hex, 2 — unsigned integer, 3 — signed integer).
     - bits 9…10: SIMD element size (0 — byte / float, 1 — word / float, 2 — dword / double, 3 — qword / double).
     - bit 11: SIMD control/status register.
     - bit 12: 8 stack dwords.
     - bit 13: 11 bytes of code before return address and 5 bytes after return address.
     - bit 14: fps, frames, elapsed time (if relative time mode is off, see `@DEBUG_OPTIONS`).

     Date/time and thread number is always included.

  <u>Returns</u> nothing.

- **0x0F** (`@SetDebugOptions`) — set debug mode. Only 16 lower bits are used, high 16 bits are ignored.

  <u>Parameters:</u>

  1. Debug option bit set:
     - bit 0: use relative time (time from intro start) in logs.
     - bit 1: debug all API calls.
     - bit 2: debug API calls with failed result only.
     - bit 3: display fps.
     - bit 4: display frame number and time.

  <u>Returns</u> nothing.



###### Threading functions

- **0x10** (`@ThreadCall`) — call user function in a separate user thread asynchronously.

  <u>Parameters:</u>

  1. Function entry address.

  <u>Returns:</u>

  - `cf`: 0 — success (`eax` = thread index), 1 — total number of user threads is too large.
  
- **0x11** (`@ParallelCalls`) — call user function in multiple threads (thread pool).

  <u>Parameters:</u>

  1. Function entry address in low 30 bits.
     - bit 30: 0 — pass intro code start address to all threads in `esi`; 1 — pass a special value specified in parameter 2 to all threads in `esi`.
     - bit 31: 0 — synchronize (wait for task finish); 1 — don't synchronize (current thread may do another job).
  2. Special value to pass to threads (only if bit 30 of parameter 1 = 1).

  <u>Returns:</u>

  - `cf`: 0 — success; 1 —  called from pool thread.

  <u>Notes:</u>

  - *This function can be called from the main or user threads only!*

- **0x12** (`@ParallelFor`) — run loop and call user function in multiple threads (thread pool) for each iteration.

  <u>Parameters:</u>

  1. Number of iterations reduced by 1 in low 30 bits (0…1'073'741'823 = 2^30^-1).
     - bit 30: 0 — pass intro code start address to all threads in `esi`; 1 — pass a special value specified in parameter 3 to all threads in `esi`.
     - bit 31: 0 — synchronize (wait for task finish); 1 — don't synchronize (current thread may do another job).
  1. Function entry address.
  1. Special value to pass to threads (only if bit 30 of parameter 1 = 1).

  <u>Returns:</u>

  - `cf`: 0 — success; 1 —  called from pool thread.

  <u>Notes:</u>

  - *This function can be called from the main or user threads only!*

- **0x13** (`@ParallelFor2D`) — run 2D loop and call user function in multiple threads (thread pool) for each iteration.

  <u>Parameters:</u>

  1. Number of iterations of outer loop reduced by 1 in low 30 bits (0…1'073'741'823 = 2^30^-1).
     - bit 30: 0 — pass intro code start address to all threads in `esi`; 1 — pass a special value specified in parameter 4 to all threads in `esi`.
     - bit 31: 0 — synchronize (wait for task finish); 1 — don't synchronize (current thread may do another job).
  2. Number of iterations of inner loop reduced by 1 in low 30 bits (0…1'073'741'823 = 2^31^-1).
     - bits 30…31 = reserved (must be 0).
  3. Function entry address.
  4. Special value to pass to threads (only if bit 30 of parameter 1 = 1).

  <u>Returns:</u>

  - `cf`: 0 — success; 1 — total number of iterations is too large or called from pool thread.

  <u>Notes:</u>

  - *This function can be called from the main or user threads only!*
  - Total number of iterations (inner * outer) must be not greater than 4'293'918'720 = 2^32^-1'048'576.

- **0x14** (`@ParallelPixels`) — call user function for every pixel, pixel group or line of screen resolution / frame buffer in multiple threads (thread pool).

  <u>Parameters:</u>

  1. Options:
     - bits 0…3 = number of pixels in group (power of two: from 0 to 8 [that encodes values from 1 to 256] or 15 for whole line).
     - bit 4: 0 — call function for pixels of screen resolution; 1 — call function for pixels of frame buffer.
     - bit 5: 0 — pass intro code start address to all threads in `esi`; 1 — pass a special value specified in parameter 3 to all threads in `esi`.
     - bit 6: 0 — synchronize (wait for task finish); 1 — don't synchronize (current thread may do another job).
     - bit 7: 0 — function entry address is specified in separate parameter (high 24 bits are ignored); 1 — function relative entry address is specified in high 24 bits.
     - bits 8…31 = function entry address (only if bit 7 = 1).
  2. Function entry address (only if bit 7 of parameter 1 = 0).
  3. Special value to pass to threads (only if bit 5 of parameter 1 = 1).

  <u>Returns:</u>

  - `cf`: 0 — success; 1 — video mode is not initialized, wrong number or pixels in group or called from pool thread.

  <u>Notes:</u>

  - *This function can be called from the main or user threads only!*
  - This function shouldn't be called if video mode is not initialized *(else exception is generated if exception mode is enabled)!*
  - If color depth (bpp) is less than 8 and number of pixel in group is less than 8/bpp then you need to use atomic bit operations when writing pixels to frame buffer.

- **0x15** (`@WaitThread`) — wait for thread function to finish execution.

  <u>Parameters:</u>

  1. Thread index or THREAD_INDEX_POOL_SYNC for all pool threads. Use timeout if bit 15 = 1. Only 16 lower bits are used, high 16 bits are ignored.
  2. Timeout in milliseconds (only if high bit of parameter 1 is set).

  <u>Returns:</u>

  - `cf`: 0 — success; 1 — time is out or thread is not running or parameter 1 = 0 when called not from the main thread.

  <u>Notes:</u>

  - Function with parameter 1 = THREAD_INDEX_POOL_SYNC (wait for all pool threads) can be called from the main or user threads only!

- **0x16** (`@ParallelWait`) — wait for parallel execution finish. <u>No parameters, no returns.</u>

  <u>Notes:</u>

  - *This function can be called from the main or user threads only!*

- **0x17** (`@Barrier`) — synchronize threads (wait when other threads call the same function).

  <u>Parameters:</u>

  1.  Number of threads (0 for all).

  <u>Returns</u> nothing.

- **0x18** (`@SyncLock`) — lock mutex.

  <u>Parameters:</u>

  1. Mutex id (bit 6: 0 — exclusive lock / for read-write access, 6 — with shared ownership / for read only access). Use timeout if bit 7 = 1. Only 8 lower bits are used, high 24 bits are ignored.
  2. Timeout in milliseconds (only if bit 7 of parameter 1 is set). If timeout = 0 then function tries to lock once.

  <u>Returns:</u>

  - `cf`: 0 — success; 1 — time is out / mutex is locked by another thread.

- **0x19** (`@SyncUnlock`) — unlock mutex.

  <u>Parameters:</u>

  1.  Mutex id (bit 6: 0 — exclusive lock / for read-write access, 1 — with shared ownership / for read only access). Only 8 lower bits are used, high 24 bits are ignored.

  <u>Returns</u> nothing.

- **0x1A** (`@WaitCondvar`) — wait until condition variable is awakened.

  <u>Parameters:</u>

  1. Condition variable id and mutex id. Only 16 lower bits are used, high 16 bits are ignored.
     - bits 0…5 = condition variable id.
     - bit 6: 0 — lock mutex; 1 — mutex is already locked.
     - bit 7: 0 — mutex id is the same as condition variable id; 1 — mutex id is specified in bits 8…13.
     - bits 8…13 = mutex id (used only if bit 7 = 1).
     - bit 14: 0 — exclusive lock / for read-write access, 6 — with shared ownership / for read only access.
     - bit 15: 0 — use timeout.
  2. Timeout in milliseconds (only if bit 15 of parameter 1 is set).

  <u>Returns:</u>

  - `cf`: 0 — success; 1 — time is out.

- **0x1B** (`@NotifyCondvar`) — notify one waiting thread.

  <u>Parameters:</u>

  1. Condition variable id (bit 6: unused; bit 7: 0 — notify one thread, 1 — notify all threads). Only 8 lower bits are used, high 24 bits are ignored.

  <u>Returns</u> nothing.

- **0x1C** (`@CallOnce`) — call user function once even if other threads try to call it.

  <u>Parameters:</u>

  1. Once flag id. Only 8 lower bits are used, high 24 bits are ignored.

  <u>Returns</u> nothing.

- **0x1D** (`@CallLocked`) — lock mutex and call user function.

  <u>Parameters:</u>

  1. Function entry address.
  2. Mutex id (bit 6: 0 — exclusive lock / for read-write access, 1 — with shared ownership / for read only access). Use timeout is bit 7 = 1. Only 8 lower bits are used, high 24 bits are ignored.
  3. Timeout in milliseconds (only if bit 7 of parameter 2 is set). If timeout = 0 then function tries to lock once.

  <u>Returns:</u>

  - `cf`: 0 — success; 1 — time is out / mutex is locked by another thread.

- **0x1F** (`@TerminateThread`) — terminate thread.

  <u>Parameters:</u>

  1. Thread index or 0 for all threads except main. Only 16 lower bits are used, high 16 bits are ignored.

  <u>Returns:</u>

  - `cf`: 0 — success; 1 — thread is not running.

  <u>Notes:</u>

  - Function with index 0 should be called from the main thread only *(else exception is generated if exception mode is enabled)! **It's not recommended to use this function at all!***

Total number of threads (including the main thread) can't be greater than 256 (in this API version). The main thread has index 0.

Mutex id, condition variable id and once flag id must be in range from 0 to 63.

Function launched by `@THREAD_CALL`, `@PARALLEL_*`, `@CALL_ONCE` and `@*CALL_LOCKED` starts with the following register values:

- All arithmetic flags (`cf`, `zf`, `pf`, `sf`, `of`, `af`) and `df` are reset.
- `eax` = thread index.
- `ebx` = CPU feature bit set.
- `ecx` = inner iteration number / number of pixel (not number of group) in line (or 0 for @ParallelCalls).
- `edx` = outer iteration number / 1D-loop iteration number / number of line (or 0 for @ParallelCalls).
- `esi` = called function entry address.
- `edi` = frame buffer address (line or pixel group start address for `@ParallelPixels`) or code end address for console mode.
- `ebp` = API function table / handler (0x08000000).



###### Video functions

- **0x20** (`@InitVideo`) — initialize video.

  <u>Parameters:</u>

  1. Screen resolution or mode number and options:
     - bits 0…12 = screen width reduced by 1 (can't be 0; encodes values 2…8192) or video mode number (if screen height (bits 16…28) = 0).
     - bits 13…14 = color mode code: 0 — 8 bpp (default color palette); 1 — 4 bpp packed (SWEETIE16 palette); 2 — 16 bpp (xRGB 1:5:5:5); 3 — 32 bpp (xRGB 8:8:8:8
     - bit 15: reserved (must be 0).
     - bits 16…28 = screen height reduced by 1 (encodes values 2…8192) or 0 if bits 0…12 contain video mode number.
     - bits 29…30 = line alignment code: 0 — default alignment (specified by header or 4-byte alignment); 1 — 64-byte alignment; 2 — alignment by 256 pixels; 3 — line width is a power of 2 (but not less than 4 bytes).
     - bit 31 = frame buffer has another size than screen resolution.
  2. Frame buffer size (only if bit 31 of parameter 1 is set): bits 0…15 = screen width reduced by 1, bits 16…31 = screen height reduced by 1. If bit 31 of parameter 1 is not set then frame buffer size is equals to screen resolution. *Frame buffer can't be less than screen resolution!*

  <u>Returns:</u>

  - `cf` = 0 — success (`edi` = frame buffer address), 1 — specified screen resolution can't be set *(in some cases, not related to correctness of parameters, exception is generated if exception mode is enabled)!*.

  <u>Notes:</u>

  - *This function can be called from the main thread only!*
  - Frame buffer can't be more than 256 MB considering alignment padding (e.g. 8192x8192 / 32 bpp, 16384x16384 / 8 bpp, 65536*8192 / 4 bpp packed).
  - If color depth (bpp) is less than 8 then screen resolution width must be multiple of 8/bpp.
  - If color depth (bpp) is less than 32 then frame buffer width must be multiple of 32/bpp.
  - Console becomes inaccessible after successful video initialization.

- **0x21** (`@CloseVideo`) — close window with image, restore old desktop resolution and allow to use console. <u>No parameters, no returns.</u>

- **0x22** (`@FillFrame`) — fill frame (memory) with specified value.

  <u>Parameters:</u>

  1. Options:
     - bit 0: 0 — fill value is 16-bit and specified in bits 16…31 of this parameter; 1 — fill value is 32-bit and specified in separate parameter
     - bit 1: 0 — copy from start of frame buffer; 1 — frame buffer address is specified in separate parameter.
     - bit 2: 0 — image size corresponds to the screen resolution; 1 — image size is specified in separate parameter.
     - bits 16…31 — fill value (if bit 0 = 0).
  2. Fill value (only if bit 0 of parameter 1 = 1).
  3. Address of frame buffer (only if bit 1 of parameter 1 = 1). This parameter can be the 2nd if fill value is 16-bit.
  4. Image size: bits 0…15 = image width, bits 16…31 = image height (only if bit 2 of parameter 1 = 1). This parameter can be the 2nd or 3rd if fill value is 16-bit and/or start of image is not specified.
  
  <u>Returns</u> nothing.
  
- **0x23** (`@DisplayFrame`) — copy image from frame buffer to video memory.

  <u>Parameters:</u>

  1. Options:
     - bit 0: 0 — synchronize with vertical retrace; 1 — no synchronization.
     - bit 1: 0 — copy from start of frame buffer; 1 — frame buffer address is specified in separate parameter.
     - bit 2: 0 — image size corresponds to the screen resolution; 1 — image size is specified in separate parameter.
     - bits 3…15 — reserved (must be 0).
     - bits 16…31 — synchronization speed limit (positive value — maximal fps, negative value — minimal interval in milliseconds after previous copying). Zero value means no speed limit.
  2. Address of frame buffer (only if bit 1 of parameter 1 = 1).
  3. Image size: bits 0…15 = image width reduced by 1, bits 16…31 = image height reduced by 1 (only if bit 1 of parameter 2 = 1). This parameter can be the 2nd if start of image is not specified.
  
  <u>Returns:</u>
  
  - `cf` = 0 — success, 1 — video is not initialized or specified image size is too large.
  
  <u>Notes:</u>
  
  - *This function can be called from the main thread only!*
  
- **0x24** (`@FrameSync`) — frame synchronization.

  <u>Parameters:</u>

  1. Synchronization speed limit (positive value — maximal fps, negative value — minimal interval in milliseconds after previous copying). Zero value means no speed limit.

  <u>Returns</u> nothing.

- **0x25** (`@SetOnePalette`) — set one palette element.

- **0x26** (`@SetFullPalette`) — set all palette elements.

- **0x27** (`@GeneratePaletteRange`) — generate palette range.

- **0x28** (`@GenerateFullPalette`) — generate all palette.

-------

+0x00: copy video buffer to video memory
+0x04: copy video buffer to video memory from specified position (edx=position: x [16 bits] and y [16 bits])
+0x08: set video mode by number (dl); ret: cf=0-ok, 1-fail
+0x0C: set video resolution and color depth (edx=parameters: width [14 bits], height [14 bits], color depth [4 bits]); ret: cf=0-ok, 1-fail
+0x10: set video mode by number and video buffer resolution (dl=mode number, ecx=video buffer resolution: width [16 bits], height [16 bits]); ret: cf=0-ok, 1-fail
+0x14: set video resolution and color depth and video buffer resolution (edx=parameters, ecx=video buffer resolution); ret: cf=0-ok, 1-fail
+0x18: get video resolution and color depth; ret: eax=parameters
+0x1C: get video buffer resolution; ret: eax=resolution
+0x20: set palette for 8-bit mode (dl=index, ecx=palette)
+0x24: set full palette for 8-bit mode (edx=address, cl=first color index, ch=last color index)



----



new functions:

- file read/write
- one-time timer
- event handlers (mouse button, keyboard key press, end of all multithreading functions...)
- get video parameters by mode number
- get sound parameters by mode number
- is key / mouse button was pressed/released since last call?
- mouse distance since last call

+0x00: copy video buffer to video memory
+0x04: copy video buffer to video memory from specified position (edx=position: x [16 bits] and y [16 bits])
+0x08: set video mode by number (dl); ret: cf=0-ok, 1-fail
+0x0C: set video resolution and color depth (edx=parameters: width [14 bits], height [14 bits], color depth [4 bits]); ret: cf=0-ok, 1-fail
+0x10: set video mode by number and video buffer resolution (dl=mode number, ecx=video buffer resolution: width [16 bits], height [16 bits]); ret: cf=0-ok, 1-fail
+0x14: set video resolution and color depth and video buffer resolution (edx=parameters, ecx=video buffer resolution); ret: cf=0-ok, 1-fail
+0x18: get video resolution and color depth; ret: eax=parameters
+0x1C: get video buffer resolution; ret: eax=resolution
+0x20: set palette for 8-bit mode (dl=index, ecx=palette)
+0x24: set full palette for 8-bit mode (edx=address, cl=first color index, ch=last color index)

+0x30: text functions

+0x40: set wave generator callback function and start the sound (edx=sound generator function, ecx=sound parameters: freq [18 bits], bits per sample [2 bits], sign [2 bits], num of channels [2 bits], buffer size [8 bits]); ret: cf=0-ok, 1-fail
+0x44: set wave generator callback function and start the sound (edx=sound generator function, cl=sound parameters); ret: cf=0-ok, 1-fail
+0x48: set wave generator callback function but don't start the sound (edx=sound generator function, ecx=sound parameters)
+0x4C: set wave generator callback function but don't start the sound (edx=sound generator function, cl=sound parameters)
+0x50: get sound parameters; ret: eax=sound parameters
+0x54: start sound; ret: cf=0-ok, 1-fail
+0x58: stop sound
+0x5C: continue sound; ret: cf=0-ok, 1-fail
+0x60: get sample number; ret: eax=sample number
+0x64: set sample number (edx=sample number)
+0x68: send short midi message (edx=message)
+0x6C: send long midi message (edx=message address, ecx=message length)

+0x70: get Esc key state; ret: cf=0-was not pressed since last call, 1-was pressed
+0x74: get key state (dl=key code); ret: cf=0-released, 1-pressed
+0x78: get key state map; ret: eax=key state map
+0x7C: get mouse position & buttons state; ret eax: x [14 bits], y [14 bits], buttons [3 bits]

-0x04: run a new thread (edx=function)
-0x08: stop all threads except main
-0x10: run multithreaded function for each pixel and sync (edx=function)
-0x14: run multithreaded function for each line and sync (edx=function)
-0x18: run multithreaded function for loop and sync (edx=function, ecx=number of iterations-1)
-0x20: run multithreaded function for each pixel but don't sync (edx=function)
-0x24: run multithreaded function for each line but don't sync (edx=function)
-0x28: run multithreaded function for loop but don't sync (edx=function, ecx=number of iterations-1)
-0x30: sync multithreaded calls
-0x34: enter critical section (dl=critical section number)
-0x38: try critical section (dl=critical section number); ret: cf=0-ok, 1-fail
-0x3C: leave critical section (dl=critical section number)

-0x40: v-sync
-0x44: delay (edx=milliseconds)
-0x48: get timer value; ret: eax=milliseconds since intro start
-0x50: set timer function (edx=function, ecx=milliseconds)
-0x54: stop timer function (edx=function)

-0x60: generate random number; ret: eax=random number (0..0xFFFFFFFF)
-0x64: generate random number (edx=max random value); ret: eax=random number

-0x7C: failed exit (al=code)
-0x80: successful exit
