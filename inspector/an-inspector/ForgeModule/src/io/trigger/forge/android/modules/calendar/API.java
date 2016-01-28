package io.trigger.forge.android.modules.calendar;

import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.Hashtable;
import java.util.Map;
import java.util.TimeZone;

import io.trigger.forge.android.core.ForgeActivity.EventAccessBlock;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeParam;
import io.trigger.forge.android.core.ForgeTask;

import android.Manifest;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.CalendarContract;
import android.provider.CalendarContract.Calendars;
import android.provider.CalendarContract.Events;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;

public class API {
	public static void listCalendars(final ForgeTask task, @ForgeParam("accessLevel") final int accessLevel) {
		ForgeApp.getActivity().requestPermission(Manifest.permission.READ_CALENDAR, new EventAccessBlock() {
			@Override
			public void run(boolean granted) {
				if (!granted) {
					task.error("Permission denied. User denied calendar access", "EXPECTED_FAILURE", null);
					return;
				}
				Uri eventUri;
				String[] projection;
				if (Build.VERSION.SDK_INT >= 14) {
					projection = new String[]{Calendars._ID, Calendars.CALENDAR_DISPLAY_NAME, Calendars.CALENDAR_COLOR, Calendars.CALENDAR_ACCESS_LEVEL};
				} else {
					projection = new String[]{"_id", "displayName", "color", "access_level"};
				}
				if (Build.VERSION.SDK_INT >= 8) {
					eventUri = Uri.parse("content://com.android.calendar/calendars");
				} else {
					eventUri = Uri.parse("content://calendar/calendars");
				}
				Cursor cursor = ForgeApp.getActivity().getContentResolver().query(eventUri, projection, null, null, "_id");
				if (cursor.moveToFirst()) {
					JsonArray result = new JsonArray();
					do {
						if (cursor.getInt(3) > accessLevel) {
							JsonObject calendar = new JsonObject();
							calendar.addProperty("id", cursor.getInt(0));
							calendar.addProperty("title", cursor.getString(1));
							calendar.addProperty("color", String.format("#%06X", (0xFFFFFF & cursor.getInt(2))));
							result.add(calendar);
						} else {
							ForgeLog.d("Ignoring calendar: '" + cursor.getString(1) + "' with access level: " + cursor.getInt(3));
						}
					} while (cursor.moveToNext());
					task.success(result);
				} else {
					task.error("Unable to read calendar info", "UNEXPECTED_FAILURE", null);
				}
				cursor.close();
			}
		});
	}


	public static void insertEvent(final ForgeTask task, @ForgeParam("details") final JsonObject details) {
		ForgeApp.getActivity().requestPermission(Manifest.permission.WRITE_CALENDAR, new EventAccessBlock() {
			@Override
			public void run(boolean granted) {
				if (!granted) {
					task.error("Permission denied. User denied calendar access", "EXPECTED_FAILURE", null);
					return;
				}
				// Need calendar id, start date, end date
				if (!details.has("calendar") || !details.has("start") || !details.has("end")) {
					task.error("Missing one or more required details: calendar, start and end", "BAD_INPUT", null);
					return;
				}

				ContentResolver cr = ForgeApp.getActivity().getContentResolver();
				ContentValues values = new ContentValues();

				// Load calendar details
				Uri calendarUri;
				String[] projection;
				if (Build.VERSION.SDK_INT >= 14) {
					projection = new String[]{Calendars._ID, Calendars.CALENDAR_TIME_ZONE};
				} else {
					projection = new String[]{"_id", "timezone"};
				}
				if (Build.VERSION.SDK_INT >= 8) {
					calendarUri = Uri.parse("content://com.android.calendar/calendars");
				} else {
					calendarUri = Uri.parse("content://calendar/calendars");
				}
				Cursor cursor = ForgeApp.getActivity().getContentResolver().query(calendarUri, projection, "_id = ?", new String[]{String.valueOf(details.get("calendar").getAsInt())}, null);
				if (cursor.moveToFirst()) {
					values.put(Events.CALENDAR_ID, details.get("calendar").getAsInt());
					values.put(Events.EVENT_TIMEZONE, cursor.getString(1));
				} else {
					task.error("Calendar does not exist");
					return;
				}

				if (details.has("title")) {
					values.put(Events.TITLE, details.get("title").getAsString());
				}
				if (details.has("location")) {
					values.put(Events.EVENT_LOCATION, details.get("location").getAsString());
				}
				if (details.has("description")) {
					values.put(Events.DESCRIPTION, details.get("description").getAsString());
				}
				if (details.has("start")) {
					values.put(Events.DTSTART, (long) (details.get("start").getAsDouble() * 1000));
				}
				if (details.has("allday")) {
					if (details.get("allday").getAsBoolean()) {
						values.put(Events.ALL_DAY, 1);
					} else {
						values.put(Events.ALL_DAY, 0);
					}
				}
				if (details.has("recurring")) {
					String recurring = details.get("recurring").getAsString();
					if (recurring.equals("daily")) {
						values.put(Events.RRULE, "FREQ=DAILY");
					} else if (recurring.equals("weekly")) {
						values.put(Events.RRULE, "FREQ=WEEKLY;BYDAY=MO");
					} else if (recurring.equals("monthly")) {
						values.put(Events.RRULE, "FREQ=MONTHLY;BYMONTHDAY=1");
					} else if (recurring.equals("yearly")) {
						values.put(Events.RRULE, "FREQ=YEARLY");
					}
					if (details.has("end")) {
						values.put(Events.DURATION, "PT" + String.valueOf((long) (details.get("end").getAsDouble()) - (long) (details.get("start").getAsDouble())) + "S");
					}
				} else {
					if (details.has("end")) {
						values.put(Events.DTEND, (long) (details.get("end").getAsDouble() * 1000));
					}
				}

				if (Build.VERSION.SDK_INT >= 14) {
					// ICS requires eventTimezone. see: http://developer.android.com/reference/android/provider/CalendarContract.Events.html
					values.put("eventTimezone", TimeZone.getDefault().getID());
				}

				Uri eventUri;
				if (Build.VERSION.SDK_INT >= 8) {
					eventUri = Uri.parse("content://com.android.calendar/events");
				} else {
					eventUri = Uri.parse("content://calendar/events");
				}
				Uri uri = cr.insert(eventUri, values);

				long eventId = Long.parseLong(uri.getLastPathSegment());
				task.success(new JsonPrimitive(eventId));
			}
		});
	}

	public static void updateEvent(final ForgeTask task, @ForgeParam("eventId") final int eventId, @ForgeParam("details") final JsonObject details) {
		ForgeApp.getActivity().requestPermission(Manifest.permission.WRITE_CALENDAR, new EventAccessBlock() {
			@Override
			public void run(boolean granted) {
				if (!granted) {
					task.error("Permission denied. User denied calendar access", "EXPECTED_FAILURE", null);
					return;
				}
				ContentResolver cr = ForgeApp.getActivity().getContentResolver();
				ContentValues values = new ContentValues();

				if (details.has("title")) {
					values.put(Events.TITLE, details.get("title").getAsString());
				}
				if (details.has("location")) {
					values.put(Events.EVENT_LOCATION, details.get("location").getAsString());
				}
				if (details.has("description")) {
					values.put(Events.DESCRIPTION, details.get("description").getAsString());
				}
				if (details.has("start")) {
					values.put(Events.DTSTART, (long) (details.get("start").getAsDouble() * 1000));
				}
				if (details.has("end")) {
					values.put(Events.DTEND, (long) (details.get("end").getAsDouble() * 1000));
				}
				if (details.has("allday")) {
					if (details.get("allday").getAsBoolean()) {
						values.put(Events.ALL_DAY, 1);
					} else {
						values.put(Events.ALL_DAY, 0);
					}
				}
				if (details.has("recurring")) {
					String recurring = details.get("recurring").getAsString();
					if (recurring.equals("daily")) {
						values.put(Events.RRULE, "FREQ=DAILY");
					} else if (recurring.equals("weekly")) {
						values.put(Events.RRULE, "FREQ=WEEKLY;BYDAY=MO");
					} else if (recurring.equals("monthly")) {
						values.put(Events.RRULE, "FREQ=MONTHLY;BYMONTHDAY=1");
					} else if (recurring.equals("yearly")) {
						values.put(Events.RRULE, "FREQ=YEARLY");
					}
				}

				Uri eventUri;
				if (Build.VERSION.SDK_INT >= 8) {
					eventUri = Uri.parse("content://com.android.calendar/events");
				} else {
					eventUri = Uri.parse("content://calendar/events");
				}
				int count = cr.update(ContentUris.withAppendedId(eventUri, eventId), values, null, null);
				if (count == 1) {
					task.success(new JsonPrimitive(eventId));
				} else {
					task.error("Failed to find event to update", "EXPECTED_FAILURE", null);
				}
			}
		});
	}

	public static void getEvent(final ForgeTask task, @ForgeParam("eventId") final int eventId) {
		ForgeApp.getActivity().requestPermission(Manifest.permission.READ_CALENDAR, new EventAccessBlock() {
			@Override
			public void run(boolean granted) {
				if (!granted) {
					task.error("Permission denied. User denied calendar access", "EXPECTED_FAILURE", null);
					return;
				}
				Uri eventUri;
				String selection;
				String[] projection = new String[]{Events.TITLE, Events.DESCRIPTION, Events.EVENT_LOCATION, Events.DTSTART, Events.DTEND, Events.ALL_DAY, Events.RRULE, Events._ID, Events.CALENDAR_ID, Events.DURATION};
				if (Build.VERSION.SDK_INT >= 8) {
					eventUri = Uri.parse("content://com.android.calendar/events");
				} else {
					eventUri = Uri.parse("content://calendar/events");
				}
				Cursor cursor = ForgeApp.getActivity().getContentResolver().query(eventUri, projection, "_id = ?", new String[]{String.valueOf(eventId)}, null);
				if (cursor.moveToFirst()) {
					JsonObject result = new JsonObject();
					result.addProperty("title", cursor.getString(0));
					result.addProperty("description", cursor.getString(1));
					result.addProperty("location", cursor.getString(2));
					result.addProperty("start", (double) cursor.getLong(3) / 1000.0);
					result.addProperty("end", (double) cursor.getLong(4) / 1000.0);
					result.addProperty("allday", cursor.getInt(5) == 1);
					result.addProperty("id", cursor.getInt(7));
					result.addProperty("calendar", cursor.getInt(8));
					if (cursor.getLong(4) == 0 && cursor.getString(9) != null) {
						try {
							Duration d = new Duration();
							d.parse(cursor.getString(9));
							result.addProperty("end", (cursor.getLong(3) + d.getMillis()) / 1000.0);
						} catch (ParseException e) {
							ForgeLog.e(e.getLocalizedMessage());
						}
					}
					task.success(result);
				} else {
					task.error("Event does not exist", "EXPECTED_FAILURE", null);
				}
				cursor.close();
			}
		});
	}

	public static void getEvents(final ForgeTask task, @ForgeParam("from") final double from, @ForgeParam("to") final double to) {
		ForgeApp.getActivity().requestPermission(Manifest.permission.READ_CALENDAR, new EventAccessBlock() {
			@Override
			public void run(boolean granted) {
				if (!granted) {
					task.error("Permission denied. User denied calendar access", "EXPECTED_FAILURE", null);
					return;
				}
				Uri.Builder builder = CalendarContract.Instances.CONTENT_URI.buildUpon();
				ContentUris.appendId(builder, (long) (from * 1000));
				ContentUris.appendId(builder, (long) (to * 1000));

				Uri eventUri = builder.build();
				String[] projection = new String[]{Events.TITLE, Events.DESCRIPTION, Events.EVENT_LOCATION, Events.DTSTART, Events.DTEND, Events.ALL_DAY, Events.RRULE, CalendarContract.Instances.EVENT_ID, Events.CALENDAR_ID, Events.DURATION};

				Cursor cursor = ForgeApp.getActivity().getContentResolver().query(eventUri, projection, null, null, null);

				JsonArray events = new JsonArray();
				while (cursor.moveToNext()) {
					JsonObject result = new JsonObject();
					result.addProperty("title", cursor.getString(0));
					result.addProperty("description", cursor.getString(1));
					result.addProperty("location", cursor.getString(2));
					result.addProperty("start", (double) cursor.getLong(3) / 1000.0);
					result.addProperty("end", (double) cursor.getLong(4) / 1000.0);
					result.addProperty("allday", cursor.getInt(5) == 1);
					result.addProperty("id", cursor.getInt(7));
					result.addProperty("calendar", cursor.getInt(8));
					if (cursor.getLong(4) == 0 && cursor.getString(9) != null) {
						try {
							Duration d = new Duration();
							d.parse(cursor.getString(9));
							result.addProperty("end", (cursor.getLong(3) + d.getMillis()) / 1000.0);
						} catch (ParseException e) {
							ForgeLog.e(e.getLocalizedMessage());
						}
					}
					events.add(result);
				}
				task.success(events);
				cursor.close();
			}
		});
	}

	public static void addEvent(final ForgeTask task, @ForgeParam("details") final JsonObject details) {
		ForgeApp.getActivity().requestPermission(Manifest.permission.WRITE_CALENDAR, new EventAccessBlock() {
			@Override
			public void run(boolean granted) {
				if (!granted) {
					task.error("Permission denied. User denied calendar access", "EXPECTED_FAILURE", null);
					return;
				}

				Map<Integer, String> dayMapping = new Hashtable<Integer, String>();
				dayMapping.put(Calendar.SUNDAY, "SU");
				dayMapping.put(Calendar.MONDAY, "MO");
				dayMapping.put(Calendar.TUESDAY, "TU");
				dayMapping.put(Calendar.WEDNESDAY, "WE");
				dayMapping.put(Calendar.THURSDAY, "TH");
				dayMapping.put(Calendar.FRIDAY, "FR");
				dayMapping.put(Calendar.SATURDAY, "SA");

				Intent intent = new Intent(Intent.ACTION_EDIT);
				intent.setType("vnd.android.cursor.item/event");
				if (details.has("title")) {
					intent.putExtra("title", details.get("title").getAsString());
				}
				if (details.has("location")) {
					intent.putExtra("eventLocation", details.get("location").getAsString());
				}
				if (details.has("description")) {
					intent.putExtra("description", details.get("description").getAsString());
				}
				if (details.has("start")) {
					intent.putExtra("beginTime", (long) (details.get("start").getAsDouble() * 1000));
				}
				if (details.has("end")) {
					intent.putExtra("endTime", (long) (details.get("end").getAsDouble() * 1000));
				}
				if (details.has("allday")) {
					intent.putExtra("allDay", details.get("allday").getAsBoolean());
				}
				if (details.has("recurring")) {
					String recurring = details.get("recurring").getAsString();
					if (recurring.equals("daily")) {
						intent.putExtra("rrule", "FREQ=DAILY");
					} else if (recurring.equals("weekly")) {
						Calendar cal = new GregorianCalendar();
						cal.setTimeInMillis(intent.getLongExtra("beginTime", (new Date()).getTime()));
						String shortDay = dayMapping.get(cal.get(Calendar.DAY_OF_WEEK));
						intent.putExtra("rrule", "FREQ=WEEKLY;BYDAY=" + shortDay);
					} else if (recurring.equals("monthly")) {
						Calendar cal = new GregorianCalendar();
						cal.setTimeInMillis(intent.getLongExtra("beginTime", (new Date()).getTime()));
						intent.putExtra("rrule", "FREQ=MONTHLY;BYMONTHDAY=" + cal.get(Calendar.DAY_OF_MONTH));
					} else if (recurring.equals("yearly")) {
						intent.putExtra("rrule", "FREQ=YEARLY");
					}
				}
				ForgeApp.getActivity().startActivity(intent);
				ForgeApp.getActivity().addResumeCallback(new Runnable() {
					@Override
					public void run() {
						long max_val = 0;
						Uri eventUri;
						if (Build.VERSION.SDK_INT >= 8) {
							eventUri = Uri.parse("content://com.android.calendar/events");
						} else {
							eventUri = Uri.parse("content://calendar/events");
						}
						Cursor cursor = ForgeApp.getActivity().getContentResolver().query(eventUri, new String[]{"MAX(_id) as max_id"}, null, null, "_id");
						if (cursor.moveToFirst()) {
							max_val = cursor.getLong(cursor.getColumnIndex("max_id"));
							task.success(new JsonPrimitive(max_val));
						} else {
							task.error("Event created but ID could not be found", "UNEXPECTED_FAILURE", null);
						}
						cursor.close();
					}
				});
			}
		});
	}

	public static void editEvent(final ForgeTask task, @ForgeParam("eventId") final int eventId) {
		ForgeApp.getActivity().requestPermission(Manifest.permission.WRITE_CALENDAR, new EventAccessBlock() {
			@Override
			public void run(boolean granted) {
				if (!granted) {
					task.error("Permission denied. User denied calendar access", "EXPECTED_FAILURE", null);
					return;
				}
				Uri uri;
				if (Build.VERSION.SDK_INT >= 8) {
					uri = ContentUris.withAppendedId(Uri.parse("content://com.android.calendar/events"), eventId);
				} else {
					uri = ContentUris.withAppendedId(Uri.parse("content://calendar/events"), eventId);
				}
				Intent intent = new Intent(Intent.ACTION_EDIT).setData(uri);
				ForgeApp.getActivity().startActivity(intent);
				ForgeApp.getActivity().addResumeCallback(new Runnable() {
					@Override
					public void run() {
						task.success(new JsonPrimitive(eventId));
					}
				});
			}
		});
	}

	public static void deleteEvent(final ForgeTask task, @ForgeParam("eventId") final int eventId) {
		ForgeApp.getActivity().requestPermission(Manifest.permission.WRITE_CALENDAR, new EventAccessBlock() {
			@Override
			public void run(boolean granted) {
				if (!granted) {
					task.error("Permission denied. User denied calendar access", "EXPECTED_FAILURE", null);
					return;
				}
				Uri uri;
				if (Build.VERSION.SDK_INT >= 8) {
					uri = ContentUris.withAppendedId(Uri.parse("content://com.android.calendar/events"), eventId);
				} else {
					uri = ContentUris.withAppendedId(Uri.parse("content://calendar/events"), eventId);
				}

				ForgeApp.getActivity().getContentResolver().delete(uri, null, null);
				task.success();
			}
		});
	}
}
