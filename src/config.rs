use smithay::{
    input::keyboard::ModifiersState,
    reexports::winit::platform::unix::x11::util::modifiers::Modifier,
};

use crate::input_handler::KeyAction;

use xkbcommon::xkb;

#[derive(Debug, Clone)]
pub struct Config {
    pub mod_key: Modifier,
    pub keybindings: Vec<Keybinding>,
}

impl Config {
    /// TODO
    ///
    /// Get config from file or smth idk
    pub fn get() -> Config {
        return Config::default();
    }

    /// TODO
    ///
    /// Returns default config.
    pub fn default() -> Config {
        return Config {
            // `Modifier::Ctrl` is used by default because
            // it is easier to use when developing. Bindings
            // like the below "quit" would not be intercepted
            // by the running environment.
            mod_key: Modifier::Ctrl,
            keybindings: vec![
                Keybinding {
                    mods: vec![Modifier::Ctrl],
                    key: xkb::KEY_q,
                    action: KeyAction::Quit,
                    help: "Quit the compositor".into(),
                },
                Keybinding {
                    mods: vec![Modifier::Ctrl],
                    key: xkb::KEY_Return,
                    action: KeyAction::Run("kitty".into()),
                    help: "Launch terminal".into(),
                },
            ],
        };
    }

    /// TODO
    ///
    /// Fixes invalid values by replacing
    /// them with default values.
    pub fn fix(&mut self) {
        // Discard mod keys that are not allowed.
        if self.mod_key != Modifier::Logo
            || self.mod_key != Modifier::Ctrl
            || self.mod_key != Modifier::Alt
        {
            self.mod_key = Modifier::Ctrl;
        }

        self.mod_key = Config::default().mod_key;
    }
}

#[derive(Debug, Clone)]
pub struct Keybinding {
    pub mods: Vec<Modifier>,
    pub key: xkb::Keysym,
    pub action: KeyAction,
    pub help: String,
}

impl Keybinding {
    /// Checks if mod keys required by
    /// the Keybinding are pressed.
    pub fn mods_pressed(&self, modstates: ModifiersState) -> bool {
        return if self.to_modstate() == ModState::now(modstates) {
            true
        } else {
            false
        };
    }

    /// Returns a `ModState` object
    /// based off of `self.mods`
    pub fn to_modstate(&self) -> ModState {
        let mut output = ModState {
            logo: false,
            ctrl: false,
            alt: false,
            shift: false,
        };

        for i in 0..self.mods.len() {
            match self.mods[i] {
                Modifier::Logo => {
                    output.logo = true;
                }
                Modifier::Ctrl => {
                    output.ctrl = true;
                }
                Modifier::Alt => {
                    output.alt = true;
                }
                Modifier::Shift => {
                    output.shift = true;
                }
            }
        }

        return output;
    }

    /// A simpler way to create a new Keybinding.
    pub fn new(
        mods: Vec<Modifier>,
        key: xkb::Keysym,
        action: KeyAction,
        help: String,
    ) -> Keybinding {
        return Keybinding {
            mods,
            key,
            action,
            help,
        };
    }
}

#[derive(Debug, PartialEq)]
pub struct ModState {
    logo: bool,
    ctrl: bool,
    alt: bool,
    shift: bool,
}

impl ModState {
    /// Returns a struct containing
    /// the state of each mod key.
    pub fn now(modstates: ModifiersState) -> ModState {
        return ModState {
            logo: modstates.logo,
            ctrl: modstates.ctrl,
            alt: modstates.alt,
            shift: modstates.shift,
        };
    }
}
