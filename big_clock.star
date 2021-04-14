load("render.star", "render")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")

TTL = 3600

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

def main(config):
    # Get the current time in 24 hour format
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    hh = now.format("15") # "03" for 12 hour time
    mm = now.format("04")
    ss = now.format("05")

    # Get sunrise/sunset times
    lat = config.get("lat") and float(config.get("lat")) or 37.541290
    lng = config.get("lon") and float(config.get("lon")) or -77.434769
    data = cache.get("data")
    if data != None:
      print("Hit! Displaying cached data.")
    else:
      print("Miss! Calling API.")
      resp = http.get("https://api.sunrise-sunset.org/json?lat=%f&lng=%f" % (lat, lng))
      if resp.status_code != 200:
        fail("API request failed with status %d", resp.status_code)

      data = resp.body()
      cache.set("data", data, ttl_seconds=TTL)
    json_data = json.loads(data)
    # Because the times returned by this API do not include the date, we need to
    # strip the date from "now" to get the current time in order to perform
    # acurate comparissons.
    current_time=time.time(now.format('3:04:05 PM'), format="3:04:05 PM").in_location(timezone)
    sunrise=time.time(json_data['results']['sunrise'], format="3:04:05 PM").in_location(timezone)
    sunset=time.time(json_data['results']['sunset'], format="3:04:05 PM").in_location(timezone)

    # Set color to red at night, and white during the day
    color = "#800"
    if current_time > sunrise and current_time < sunset:
        color = "#fff"

    return render.Root(
        delay = 1000,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            get_num_image(hh[0], color),
                            get_num_image(hh[1], color),
                            render.Box(
                              width  = 4,
                              height = 14,
                              color = color,
                              child = render.Image(src=SEP),
                            ), # Seperator
                            get_num_image(mm[0], color),
                            get_num_image(mm[1], color),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            get_num_image(hh[0], color),
                            get_num_image(hh[1], color),
                            render.Box(width = 4), # Seperator
                            get_num_image(mm[0], color),
                            get_num_image(mm[1], color),
                        ],
                    ),
                ]
            )
        )
    )
