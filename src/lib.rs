use zed_extension_api as zed;

struct HujsonExtension;

impl zed::Extension for HujsonExtension {
    fn new() -> Self {
        HujsonExtension
    }
}

zed::register_extension!(HujsonExtension);
