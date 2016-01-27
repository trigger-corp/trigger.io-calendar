package io.trigger.forge.android.modules.calendar;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeEventListener;

public class EventListener extends ForgeEventListener {

	static final int PERMISSIONS_REQUEST = 1;
	
	@Override
    public void onCreate(Bundle savedInstanceState) {
		if (!checkPermissions()) {
			ActivityCompat.requestPermissions(ForgeApp.getActivity(), new String[] {  
				Manifest.permission.READ_CALENDAR,
				Manifest.permission.WRITE_CALENDAR
			}, PERMISSIONS_REQUEST);
		}
	}
	
	public static boolean checkPermissions() {
		return ContextCompat.checkSelfPermission(ForgeApp.getActivity(), Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED &&
			   ContextCompat.checkSelfPermission(ForgeApp.getActivity(), Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED;
	}
}
