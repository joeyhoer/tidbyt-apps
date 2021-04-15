load("render.star", "render")
load("re.star", "re")
load("http.star", "http")
load("cache.star", "cache")

TTL = 3600

def rend_number(num):
    return render.Padding(
        pad = 1,
        child = render.Circle(
            color = "#fff",
            diameter = 14,
            child = render.Text(
                content = num,
                font = "5x8",
                color = "#000",
            )
        )
    )

def main(config):
    # Get winning numbers
    data = cache.get("data")
    if data != None:
      print("Hit! Displaying cached data.")
    else:
      print("Miss! Calling API.")
      resp = http.get("https://www.valottery.com/resulttable.xml")
      if resp.status_code != 200:
        fail("API request failed with status %d", resp.status_code)

      data = resp.body()
      cache.set("data", data, ttl_seconds=TTL)

    # Games:
    # - pick3:draw1
    # - pick3:draw2
    # - pick4:draw1
    # - pick4:draw2
    # - cash5
    # - megaMillions
    # - powerBall
    # - cash4Life
    # - moneyBall
    # - decadesofDollars
    # - bankAMillion
    game="cash5"
    element=''

    # Handle pick3/4
    if len(re.match('^pick', game)) > 0:
        game_parts=re.match('(pick[0-9]):(draw[0-9])', game)
        pick_game=game_parts[0][1]
        pick_draw=game_parts[0][2]
        pick_data=re.match('(?s:<'+pick_game+'>.*</'+pick_game+'>)', data)[0][0]
        element=re.findall('.*'+pick_draw+'.*', pick_data)[0]
    else:
        element=re.findall('.*'+game+'.*', data)[0]
    print(element)

    number_attrs=re.match('N[0-9]+="([^"]*)"', element)
    winning_numbers=[]
    for match in number_attrs:
        winning_numbers.append(match[1])
    # print(winning_numbers)

    # This should max out at 2 rows, as 3 rows exceed the height of the display
    max_children=4
    if len(winning_numbers) > 4:
        max_children=int((len(winning_numbers)+1)/2)
    rows_children=[]
    for index, winning_number in enumerate(winning_numbers, 0):
        row=int(index/max_children)
        if row > (len(rows_children) - 1):
            rows_children.append([])
        rows_children[row].append(rend_number(winning_number))
    rows=[]
    for row_children in rows_children:
        rows.append(
            render.Row(
                main_align = "space_evenly",
                cross_align = "center",
                children = row_children
            )
        )

    return render.Root(
        render.Row(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = rows
                ),
            ]
        )
    )
