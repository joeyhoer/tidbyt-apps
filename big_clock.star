load("render.star", "render")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")

# Default configuration values
TIMEZONE = "America/New_York"
LATITUDE = 37.541290
LONGITUDE = -77.434769
IS_24_HOUR_FORMAT = True
HAS_LEADING_ZERO = False
HAS_FLASHING_SEPERATOR = True
TTL = 3600
COLOR_DAYTIME="#fff"
COLOR_NIGHTTIME="#200" # Super dim red

NUMBER_IMGS=[
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAqSURBVHgBY7B
/wDD/BMP5GQwPLPChAxIMDRwMYABkALn41QMNBBoLNBwAHrcge26o7fIAAAAASUVORK5CYII=
""", # 0
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAZSURBVHgBYwA
BDgYGCQYGC7xIAqyMgVT1AOfwBOG2xNZsAAAAAElFTkSuQmCC
""", # 1
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBY7B
/wCB/goF/BgODBV4kAVQGVAxC8w8wHGBgeIAXnW8AKgMqBgBzoBbH0MZ6/gAAAABJRU5ErkJggg==
""", # 2
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAlSURBVHgBY7B
/wCB/goF/BgODBV4kAVQGVAxRD+TiVw80EKIeAJk5DfdkeUVkAAAAAElFTkSuQmCC
""", # 3
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBYwC
CBg6GAxIMDyzwIJCC+ScY7B+AkPwJBgYJBgYLPAisgANoNgDVyhQd//DRbQAAAABJRU5ErkJggg==
""", # 4
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAuSURBVHgBY7B
/wDD/AMP5BoYHDPjQAQagMqBiEJI/wcAgwcBggQ/xzwAqAyoGABq+Fsfy3SMpAAAAAElFTkSuQmCC
""", # 5
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAsSURBVHgBY7R
fyDhfkfH8RsYHCvjQAQegMqBisHpNxgMRjA/wovMngcqAigEwiCIRDKuGtwAAAABJRU5ErkJggg==
""", # 6
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAhSURBVHgBY7B
/wCB/goF/BgODBV4kwcDAwQAFHEAukeoB0jsHbnVM+9YAAAAASUVORK5CYII=
""", # 7
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAmSURBVHgBY7B
/wDD/BMP5GQwPLPChAxJAZUDFEPVALn71QAMh6gHctSR33GtExAAAAABJRU5ErkJggg==
""", # 8
"""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAgAQAAAADhos85AAAAAnRSTlMAAQGU/a4AAAAuSURBVHgBY7B
/wDD/BMP5GQwPLPChAxJAZUDFICR/goFBgoHBAh/in8EgD1IPAMkGGTcArQUNAAAAAElFTkSuQmCC
""", # 9
]

SEP = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAQAAAAOAQAAAAAgEYC1AAAAAnRSTlMAAQGU/a4AAAAPSURBVHgBY0g
AQzQAEQUAH5wCQbfIiwYAAAAASUVORK5CYII=
""")

# Convert a string to a boolean
# This is useful, as config variables are passed as strings
def string_to_bool(s):
  if s == "True":
    return True
  return False

# It would be easier to use a custom font, but we can use images instead.
# The images have a black background and transparent foreground. This
# allows us to change the color dynamically.
def get_num_image(num, color):
  return render.Box(
    width  = 13,
    height = 32,
    color = color,
    child = render.Image(src=base64.decode(NUMBER_IMGS[int(num)])),
  )

def get_time_image(t, color, is_24_hour_format=True, has_leading_zero=False, has_seperator=True):
  hh = t.format("03") # Formet for 12 hour time
  if is_24_hour_format == True:
    hh = t.format("15") # Format for 24 hour time
  mm = t.format("04")
  ss = t.format("05")

  seperator=render.Box(
      width  = 4,
      height = 14,
      color = color,
      child = render.Image(src=SEP),
    )
  if not has_seperator:
    seperator=render.Box(
      width  = 4
    )

  hh0=get_num_image(int(hh[0]), color)
  if int(hh[0]) == 0 and has_leading_zero == False:
    hh0=render.Box(
      width  = 13
    )

  return render.Row(
    expanded = True,
    main_align = "space_between",
    cross_align = "center",
    children = [
      hh0,
      get_num_image(int(hh[1]), color),
      seperator,
      get_num_image(int(mm[0]), color),
      get_num_image(int(mm[1]), color),
    ],
  )

def main(config):
  # Get the current time in 24 hour format
  timezone = config.get("timezone") or TIMEZONE
  now = time.now().in_location(timezone)

  # Fetch sunrise/sunset times
  lat = config.get("latitude") and float(config.get("latitude")) or LATITUDE
  lng = config.get("longitude") and float(config.get("longitude")) or LONGITUDE
  data = cache.get("data")
  # If cached data does not exist, fetch the data and cache it
  if data == None:
    # print("Miss! Calling API.")
    resp = http.get("https://api.sunrise-sunset.org/json?lat=%f&lng=%f" % (lat, lng))
    if resp.status_code != 200:
      fail("API request failed with status %d", resp.status_code)
    data = resp.body()
    cache.set("data", data, ttl_seconds=TTL)
  json_data = json.decode(data)

  # Because the times returned by this API do not include the date, we need to
  # strip the date from "now" to get the current time in order to perform
  # acurate comparissons.
  # Local time must be localized with a timezone
  current_time=time.parse_time(now.format('3:04:05 PM'), format="3:04:05 PM", location=timezone)
  day_end=time.parse_time('11:59:59 PM', format="3:04:05 PM", location=timezone)
  if json_data != None:
    # API results are returned in UPC, so we will not pass a timezone here
    sunrise=time.parse_time(json_data['results']['sunrise'], format="3:04:05 PM")
    sunset=time.parse_time(json_data['results']['sunset'], format="3:04:05 PM")

  # Get config values
  is_24_hour_format = string_to_bool(config.get("is_24_hour_format")) if config.get("is_24_hour_format") else IS_24_HOUR_FORMAT
  has_leading_zero = string_to_bool(config.get("has_leading_zero")) if config.get("has_leading_zero") else HAS_LEADING_ZERO
  has_flashing_seperator = string_to_bool(config.get("has_flashing_seperator")) if config.get("has_flashing_seperator") else HAS_FLASHING_SEPERATOR
  color_daytime = string_to_bool(config.get("color_daytime")) if config.get("color_daytime") else COLOR_DAYTIME
  color_nighttime = string_to_bool(config.get("color_nighttime")) if config.get("color_nighttime") else COLOR_NIGHTTIME

  frames=[]
  print_time=current_time
  for i in range(0, 1): # 1440
    # Set different color during day and night
    color = color_nighttime
    if json_data != None:
      if print_time > sunrise and print_time < sunset:
        color = color_daytime
    frames.append(get_time_image(print_time, color, is_24_hour_format=is_24_hour_format, has_leading_zero=has_leading_zero, has_seperator=True))
    if has_flashing_seperator:
      frames.append(get_time_image(print_time, color, is_24_hour_format=is_24_hour_format, has_leading_zero=has_leading_zero, has_seperator=False))
    print_time=print_time+time.minute
    # If time is tomorrow, reset to today
    # This simplifies sunset/sunrise calculations
    if print_time > day_end:
      print_time=print_time-(time.hour*24)

  return render.Root(
    delay = 500, # 1000ms = 1s
    child = render.Box(
      child = render.Animation(
        children = frames
      )
    )
  )
