function validateWLEDState(state) {
    const validProps = [
        'on', 'bri', 'ps',
    ];

    // Validate each property in the state
    for (const key in state) {
        if (!validProps.includes(key)) {
            return false;
        }
    }

    return true;
}

function transformPresetValue(presetValue) {
    // Convert preset value to proper WLED state format
    return {
        on: presetValue.on !== undefined ? presetValue.on : true,
        bri: presetValue.brightness || 255,
        seg: presetValue.effects || []
    };
}

module.exports = {
    validateWLEDState,
    transformPresetValue
};