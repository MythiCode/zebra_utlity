//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package com.professor.zebrautility;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothClass;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import com.zebra.sdk.comm.ConnectionException;
import com.zebra.sdk.comm.internal.BluetoothHelper;
import com.zebra.sdk.comm.internal.BtServiceDiscoverer;
import com.zebra.sdk.printer.discovery.DeviceFilter;
import com.zebra.sdk.printer.discovery.DiscoveredPrinterBluetooth;
import com.zebra.sdk.printer.discovery.DiscoveryHandler;
import com.zebra.sdk.printer.discovery.ServiceDiscoveryHandler;

import java.util.HashMap;
import java.util.Map;

public class BluetoothDiscoverer {
    private Context mContext;
    private DiscoveryHandler mDiscoveryHandler;
    BluetoothDiscoverer.BtReceiver btReceiver;
    BluetoothDiscoverer.BtRadioMonitor btMonitor;
    private DeviceFilter deviceFilter;

    private BluetoothDiscoverer(Context var1, DiscoveryHandler var2, DeviceFilter var3) {
        this.mContext = var1;
        this.deviceFilter = var3;
        this.mDiscoveryHandler = var2;
    }

    public static void findPrinters(Context var0, DiscoveryHandler var1, DeviceFilter var2) throws ConnectionException {
        BluetoothAdapter var3 = BluetoothAdapter.getDefaultAdapter();
        if (var3 == null) {
            var1.discoveryError("No bluetooth radio found");
        } else if (!var3.isEnabled()) {
            var1.discoveryError("Bluetooth radio is currently disabled");
        } else {
            if (var3.isDiscovering()) {
                var3.cancelDiscovery();
            }

            (new BluetoothDiscoverer(var0.getApplicationContext(), var1, var2)).doBluetoothDisco();
        }

    }

    public static void findPrinters(Context var0, DiscoveryHandler var1) throws ConnectionException {
        DeviceFilter var2 = new DeviceFilter() {
            public boolean shouldAddPrinter(BluetoothDevice var1) {
                return true;
            }
        };
        findPrinters(var0, var1, var2);
    }

    public static void findServices(Context var0, String var1, ServiceDiscoveryHandler var2) {
        BtServiceDiscoverer var3 = new BtServiceDiscoverer(BluetoothHelper.formatMacAddress(var1), var2);
        var3.doDiscovery(var0);
    }

    private void unregisterTopLevelReceivers(Context var1) {
        if (this.btReceiver != null) {
            var1.unregisterReceiver(this.btReceiver);
        }

        if (this.btMonitor != null) {
            var1.unregisterReceiver(this.btMonitor);
        }

    }

    private void doBluetoothDisco() {
        this.btReceiver = new BluetoothDiscoverer.BtReceiver();
        this.btMonitor = new BluetoothDiscoverer.BtRadioMonitor();
        IntentFilter var1 = new IntentFilter("android.bluetooth.device.action.FOUND");
        IntentFilter var2 = new IntentFilter("android.bluetooth.adapter.action.DISCOVERY_FINISHED");
        IntentFilter var3 = new IntentFilter("android.bluetooth.adapter.action.STATE_CHANGED");
        this.mContext.registerReceiver(this.btReceiver, var1);
        this.mContext.registerReceiver(this.btReceiver, var2);
        this.mContext.registerReceiver(this.btMonitor, var3);
        BluetoothAdapter.getDefaultAdapter().startDiscovery();
    }

    private class BtRadioMonitor extends BroadcastReceiver {
        private BtRadioMonitor() {
        }

        public void onReceive(Context var1, Intent var2) {
            String var3 = var2.getAction();
            if ("android.bluetooth.adapter.action.STATE_CHANGED".equals(var3)) {
                Bundle var4 = var2.getExtras();
                int var5 = var4.getInt("android.bluetooth.adapter.extra.STATE");
                if (var5 == 10) {
                    BluetoothDiscoverer.this.mDiscoveryHandler.discoveryFinished();
                    BluetoothDiscoverer.this.unregisterTopLevelReceivers(var1);
                }
            }

        }
    }

    private class BtReceiver extends BroadcastReceiver {
        private static final int BLUETOOTH_PRINTER_CLASS = 1664;
        private Map<String, BluetoothDevice> foundDevices;

        private BtReceiver() {
            this.foundDevices = new HashMap();
        }

        public void onReceive(Context var1, Intent var2) {
            String var3 = var2.getAction();
            if ("android.bluetooth.device.action.FOUND".equals(var3)) {
                this.processFoundPrinter(var2);
            } else if ("android.bluetooth.adapter.action.DISCOVERY_FINISHED".equals(var3)) {
                BluetoothDiscoverer.this.mDiscoveryHandler.discoveryFinished();
                BluetoothDiscoverer.this.unregisterTopLevelReceivers(var1);
            }

        }

        private void processFoundPrinter(Intent var1) {
            BluetoothDevice var2 = (BluetoothDevice)var1.getParcelableExtra("android.bluetooth.device.extra.DEVICE");
            if (!this.foundDevices.keySet().contains(var2.getAddress()) && BluetoothDiscoverer.this.deviceFilter != null && BluetoothDiscoverer.this.deviceFilter.shouldAddPrinter(var2) && this.isPrinterClass(var2)) {
                BluetoothDiscoverer.this.mDiscoveryHandler.foundPrinter(new DiscoveredPrinterBluetooth(var2.getAddress(), var2.getName()));
                this.foundDevices.put(var2.getAddress(), var2);
            }

        }

        private boolean isPrinterClass(BluetoothDevice var1) {
            BluetoothClass var2 = var1.getBluetoothClass();
            if (var2 != null) {
                return var2.getDeviceClass() == 1664;
            } else {
                return false;
            }
        }
    }
}
