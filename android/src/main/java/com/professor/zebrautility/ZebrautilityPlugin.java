package com.professor.zebrautility;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.ArrayList;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * ZebrautilityPlugin
 */
public class ZebrautilityPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private FlutterPluginBinding flutterPluginBinding;
    private ActivityPluginBinding binding;
    private ArrayList<Printer> printers = new ArrayList<>();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "zebrautility");
        this.flutterPluginBinding = flutterPluginBinding;
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
        if (call.method.equals("getInstance")) {
            Printer printer = new Printer(binding, flutterPluginBinding.getBinaryMessenger());
            result.success(printer.toString());
            printers.add(printer);
        }

    }


    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.binding = binding;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}
