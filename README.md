# adventure

## Running in the browser (xroar-online)

You can run the built disk image `ADV.DSK` using the xroar-online emulator hosted at https://colorcomputerarchive.com/xroar-online/.

Steps:

1. Open the emulator page in your browser: https://colorcomputerarchive.com/xroar-online/
2. Click the "Disk / Tape" tab (or the disk icon) to open the disk management UI.
3. Use the "Upload" or "Add" button and select the `ADV.DSK` file from this repository (or from your local build output). The site will add the disk image to the emulator.
4. Back in the emulator main view, make sure the virtual drive contains `ADV.DSK` and power-cycle the emulated machine if needed (there's usually a reset/power button in the UI).
5. The emulator will boot from the disk image. If the disk image contains an auto-run binary (`adv.bin`), the game should start automatically. Otherwise, use the emulated BASIC/OS prompt to load and run the binary (for example, use `LOAD`/`RUN` commands according to the targeted platform's loader in the emulator UI).

Notes/Tips:

- If the emulator reports the disk but nothing happens, try using the emulator's reset/power button after you add the disk.
- If the disk file doesn't boot automatically, check the disk's directory listing in the emulator (some interfaces show a file list) and run the appropriate loader command from the emulated prompt.
- If you build locally with `make`, the resulting `ADV.DSK` will be updated; re-upload it to the emulator after building.

Demo GIF

Below is a small inline demo placeholder for the emulator UI. Replace this with your own animated GIF (recommended filename `docs/xroar-demo.gif`) to show a short walkthrough of loading `ADV.DSK`.

![xroar demo](data:image/gif;base64,R0lGODlhAQABAPAAAP///wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==)

To include a real GIF in the repository, add your file at `docs/xroar-demo.gif` and then replace the image URL above with `docs/xroar-demo.gif`.
