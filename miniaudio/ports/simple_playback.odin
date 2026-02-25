package main

import "base:runtime"

import "core:fmt"
import "core:os"

import ma "vendor:miniaudio"

data_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frame_count: u32) {
	decoder := (^ma.decoder)(device.pUserData)
	if decoder == nil {
		return
	}

	ma.decoder_read_pcm_frames(decoder, output, u64(frame_count), nil)
}

main :: proc() {
	args := runtime.args__
	if len(args) < 2 {
		fmt.eprintfln("No input file.")
		os.exit(-1)
	}

	decoder: ma.decoder
	result := ma.decoder_init_file(args[1], nil, &decoder)
	if result != .SUCCESS {
		fmt.eprintfln("Could not load file: %s", args[1])
		os.exit(-2)
	}

	device_config := ma.device_config_init(.playback)
	device_config.playback.format   = decoder.outputFormat
	device_config.playback.channels = decoder.outputChannels
	device_config.sampleRate        = decoder.outputSampleRate
	device_config.dataCallback      = data_callback
	device_config.pUserData         = &decoder

	device: ma.device
	if ma.device_init(nil, &device_config, &device) != .SUCCESS {
		fmt.eprintfln("Failed to open playback device.")
		ma.decoder_uninit(&decoder)
		os.exit(-3)
	}

	if ma.device_start(&device) != .SUCCESS {
		fmt.eprintfln("Failed to start playback device.")
		ma.device_uninit(&device)
		ma.decoder_uninit(&decoder)
		os.exit(-4)
	}

	fmt.printfln("Press Enter to quit...")
	p: [1]byte
	os.read(os.stdin, p[:])

	ma.device_uninit(&device)
	ma.decoder_uninit(&decoder)
}
