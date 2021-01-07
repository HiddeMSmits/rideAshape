import gpxpy
import re
from urllib.request import urlopen
import openrouteservice

gpxFile = open('/Users/Hidde/RideADick/python/gpxFiles/penis.gpx', 'r')
gpx = gpxpy.parse(gpxFile)

userCoordinates = [52.0708544,5.2068329]
#try:
#    userCoordinates[0] = float(input('user defined latitude: '))
#except:
#    userCoordinates[0] = 0
#try:
#    userCoordinates[1] = float(input('user defined longitude: '))
#except:
#    userCoordinates[1] = 0

def createNewCoords(gpx, userCoordinates, sizeFactor = 1):
    newCoord = []

    for i in range(0, len(gpx.waypoints)):
        waypoint = gpx.waypoints[i]

        if i == 0:
            lat0 = float(format(waypoint.latitude))
            lon0 = float(format(waypoint.longitude))

        latI = float(format(waypoint.latitude))
        lonI = float(format(waypoint.longitude))

        deltaLatCord = latI - lat0
        deltaLonCord = lonI - lon0


        newCoord.append([ deltaLonCord * sizeFactor + userCoordinates[1], deltaLatCord * sizeFactor + userCoordinates[0]])
    return(newCoord)

def WriteGPX(newCoord, filePath):
    gpx = gpxpy.gpx.GPX()

    # Create first track in our GPX:
    gpx_track = gpxpy.gpx.GPXTrack()
    gpx.tracks.append(gpx_track)

    # Create first segment in our GPX track:
    gpx_segment = gpxpy.gpx.GPXTrackSegment()
    gpx_track.segments.append(gpx_segment)

    # Create points:
    for i in newCoord:
        gpx_segment.points.append(gpxpy.gpx.GPXTrackPoint(i[0], i[1]))
    f = open(filePath, 'w')
    f.write(gpx.to_xml())
    f.close()

def retrieveClosestStreet(newCoord):
    streetCord = []
    for i in newCoord:
        lat = i[0]
        lon = i[1]
        url = "https://nominatim.openstreetmap.org/reverse?format=xml&lat=" + str(lat) +  "&lon=" + str(lon) +  "&zoom=18&addressdetails=1"
        f = urlopen(url)
        myfile = f.read().decode("utf-8")
        myfile = myfile.split(">")
        res = myfile[2]
        res = res.split()

        lat = [j for j in res if j.startswith('lat')][0]
        print(lat)
        lat = lat[5:len(lat)-1]

        lon = [j for j in res if j.startswith('lon')][0]
        print(lon)
        lon = lon[5:len(lon)-1]
        print([lat, lon])

        streetCord.append([lat, lon])
    print(streetCord)
    return(streetCord)

def OSRM(coord):
    string = ''
    for i in coord:
        twoCord = str(i[1]) + ',' + str(i[0])
        string = string + twoCord + ';'
    string = string[0:len(string)-1]
    url = 'http://router.project-osrm.org/route/v1/cycling/' + string + '?overview=false&steps=false&annotations=false'
    print(url)
    f = urlopen(url)
    myfile = f.read().decode("utf-8")
    print(type(myfile))
    test = myfile.split('[', 1)
    #[1].split(']')[0]
    print(test)

newCoord = createNewCoords(gpx, userCoordinates)
client = openrouteservice.Client(key="5b3ce3597851110001cf624816a1077b8bbc475ab042cfdfdc28042e") # Specify your personal API key
routes = client.directions(newCoord, radiuses = [1000]*len(newCoord), profile='cycling-regular')

print(routes)
#streetCord = retrieveClosestStreet(newCoord)
#print(newCoord)
#WriteGPX(newCoord, '/Users/Hidde/RideADick/python/gpxFiles/newPenis.gpx')


