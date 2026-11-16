#include "hidhelper.h"
#include "mousesettings.h"
#include <QApplication>
#include <QMessageBox>
#include <QString>
#include <algorithm>


hid_device_* HIDHelper::openMouseInterface(QWidget *parent) {
    hid_device *handle = openKeyboardInterface();

    if(!handle) {
        qCritical("Cannot find device with the designated Vendor/Product ID");
        QMessageBox::critical(parent, "Mouse unavailable",
            "Cannot access a supported mouse. Check that it is connected and that "
            "the supplied udev rules are installed, then reconnect it. "
            "Run this application as your normal desktop user.");
    }

    return handle;
}

hid_device_* HIDHelper::openKeyboardInterface() {
    for(const VendorProductID &vpid : supportedDevices) {
        hid_device_info *infos = hid_enumerate(vpid.vendorId, vpid.productId);
        hid_device *handle = nullptr;
        for(hid_device_info *info = infos; info; info = info->next) {
            if(info->interface_number == 1) {
                handle = hid_open_path(info->path);
                if(handle) break;
            }
        }
        hid_free_enumeration(infos);
        if(handle) return handle;
    }
    return nullptr;
}

void HIDHelper::sendMouseReport(hid_device *dev, unsigned char updateType, unsigned char forComponent, unsigned char data, unsigned char enabledDpiProfile) {
    unsigned char byteData[6]{0};
    byteData[0] = forComponent;
    byteData[1] = data;
    byteData[2] = enabledDpiProfile;

    sendRawMouseReport(dev, updateType, byteData, 3);
}

void HIDHelper::sendRawMouseReport(hid_device *dev, unsigned char updateType, unsigned char data[6], int dataLength) {
    if(!dev || dataLength < 0 || dataLength > 6 || (dataLength && !data)) {
        qWarning("Invalid mouse feature report");
        return;
    }

    // HIDAPI supplies the USB setup packet. Only pass the report ID and payload.
    unsigned char report[8]{0x07, updateType};
    if(dataLength) std::copy_n(data, dataLength, report + 2);
    if(hid_send_feature_report(dev, report, sizeof(report)) != sizeof(report)) {
        qWarning() << "Failed to send mouse feature report:" << hid_error(dev);
    }
}

bool HIDHelper::supportsExtendedConfiguration(hid_device *dev) {
    if(!dev) return false;
    const hid_device_info *info = hid_get_device_info(dev);
    return info && !(info->vendor_id == 0x18f8 && info->product_id == 0x0f99);
}

void HIDHelper::applyMouseSettings(hid_device *dev, MouseSettings settings) {
    if(!dev) return;

    // Apply data
    // RGB
    sendMouseReport(dev, RGB, 0x7f, settings.rgbMode);

    // Scroll wheel
    sendMouseReport(dev, ScrollWheel, settings.scrollMode, 0x00);

    // This model accepts lighting and wheel mode commands; other settings
    // have not produced a confirmed effect in hardware tests.
    if(!supportsExtendedConfiguration(dev)) return;

    // Fire Rate
    sendMouseReport(dev, FireRate, 0x00, settings.fireRate);

    // Mouse bindings
    for(int i = 0; i < 7; i++) {
        sendMouseReport(dev, KeyRebind, settings.buttons[i].buttonHex, MouseSettings::actionMenuIdxToHex[settings.buttons[i].bindedAction]);
    }

    // DPI
    if(settings.applyDpi) {
        int enabledDpiBit = 0;
        for(int i = 0; i < settings.DPI_PROFILES; i++) {
            enabledDpiBit += settings.dpiProfiles[i].enabled ? 0b1 << i : 0b0 << i;
        }

        for(int i = 0; i < settings.DPI_PROFILES; i++) {
            MouseSettings::DPIProfile dpiProfile = settings.dpiProfiles[i];
            int profileBits = 0x08 + i;
            sendMouseReport(dev, DPI, settings.activeDpi, (dpiProfile.dpiValue << 4) | profileBits, enabledDpiBit);
        }
    }
}
