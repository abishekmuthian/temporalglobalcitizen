package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/antchfx/htmlquery"
	"github.com/geziyor/geziyor"
	"github.com/geziyor/geziyor/client"
	"github.com/golang-jwt/jwt"
	"github.com/google/uuid"
	"golang.org/x/oauth2/google"
	oauthJwt "golang.org/x/oauth2/jwt"
)

// [START setup]
const (
	batchUrl  = "https://walletobjects.googleapis.com/batch"
	classUrl  = "https://walletobjects.googleapis.com/walletobjects/v1/genericClass"
	objectUrl = "https://walletobjects.googleapis.com/walletobjects/v1/genericObject"
)

// [END setup]

type demoGeneric struct {
	credentials                   *oauthJwt.Config
	httpClient                    *http.Client
	batchUrl, classUrl, objectUrl string
}

type ScoreResponse struct {
	Points  int `json:"points"`
	Actions int `json:"actions"`
}

type WalletResponse struct {
	Url string `json:"url"`
}

// [START scoreHandler]
// Handles the requests to the /score.
// Scrapes the profile from Global Citizen website.
// Returns points and actions from Global Citizen
func scoreHandler(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")    // Allow any origin
	w.Header().Set("Access-Control-Allow-Methods", "GET") // Allow only GET

	queryParams := r.URL.Query()

	userName := queryParams.Get("username")

	baseURL := "https://www.globalcitizen.org/en/profile/"
	url := baseURL + userName + "/"

	geziyor.NewGeziyor(&geziyor.Options{
		StartRequestsFunc: func(g *geziyor.Geziyor) {
			g.GetRendered(url, g.Opt.ParseFunc)
		},
		ParseFunc: func(g *geziyor.Geziyor, r *client.Response) {
			responseText := scrapeProfile(r.Body)

			// Set content type as JSON for the response
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(responseText)
		},
	}).Start()

}

// [START scrapeProfile]
// Parses Global Citizen website data.
// Returns the points and the actions.
func scrapeProfile(body []byte) ScoreResponse {
	doc, err := htmlquery.Parse(strings.NewReader(string(body)))
	if err != nil {
		log.Print("Error parsing HTML: ", err)
		return ScoreResponse{}
	}
	points := 0
	pointsXpath := "/html/body/div[5]/div[1]/div/div/div[1]/div/div/div/div[4]/div/div[1]/div/h3"
	pointsNode, err := htmlquery.Query(doc, pointsXpath)
	if err == nil {
		if pointsNode != nil {
			points, err = strconv.Atoi(htmlquery.InnerText(pointsNode))
			if err != nil {
				log.Print("Error retrieving points: ", err)
			}
		}
	} else {
		log.Print("Error querying the Global Citizen data for points", err)
	}

	actions := 0
	actionsXpath := "/html/body/div[5]/div[1]/div/div/div[1]/div/div/div/div[4]/div/div[2]/div/h3"
	actionsNode, err := htmlquery.Query(doc, actionsXpath)
	if actionsNode != nil {
		actions, err = strconv.Atoi(htmlquery.InnerText(actionsNode))
		if err != nil {
			log.Print("Error retrieving actions: ", err)
		}
	} else {
		log.Print("Error querying the Global Citizen data for actions", err)
	}

	return ScoreResponse{
		Points:  points,
		Actions: actions,
	}
}

// [START auth]
// Create authenticated HTTP client using a service account file.
func (d *demoGeneric) auth() {
	googleAppCred := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	if googleAppCred == "" {
		log.Fatalln("googleAppCred not found, Check the WALLET_ISSUER_ID env variable")
	}
	b, err := os.ReadFile(googleAppCred)
	if err == nil {
		credentials, err := google.JWTConfigFromJSON(b, "https://www.googleapis.com/auth/wallet_object.issuer")
		if err == nil {
			d.credentials = credentials
			d.httpClient = d.credentials.Client(context.TODO())
		} else {
			log.Fatalln("Cannot create authenticated httpClient", err)
		}
	} else {
		log.Fatalln("Could not read the credentials file", err)
	}

}

// [END auth]

// [START createClass]
// Create a class.
func (d *demoGeneric) createClass(issuerId, classSuffix string) {
	newClass := fmt.Sprintf(`
	{
		"id": "%s.%s",
		"classTemplateInfo": {
		"cardTemplateOverride": {
			"cardRowTemplateInfos": [
			{
				"threeItems": {
				"startItem": {
					"firstValue": {
					"fields": [
						{
						"fieldPath": "object.textModulesData['level']"
						}
					]
					}
				},
				"middleItem": {
					"firstValue": {
					"fields": [
						{
						"fieldPath": "object.textModulesData['points']"
						}
					]
					}
				},
				"endItem": {
					"firstValue": {
					"fields": [
						{
						"fieldPath": "object.textModulesData['time']"
						}
					]
					}
				}
				}
			}
			]
		}
		}
	}
	`, issuerId, classSuffix)

	res, err := d.httpClient.Post(classUrl, "application/json", bytes.NewBuffer([]byte(newClass)))

	if err != nil {
		log.Println(err)
	} else {
		b, _ := io.ReadAll(res.Body)
		log.Printf("Class insert response:\n%s\n", b)
	}
}

// [END createClass]

// [START createObject]
// Create an object.
func (d *demoGeneric) createObject(issuerId, classSuffix, objectSuffix, userName, level, points, time, heroImageUrl string) error {
	newObject := fmt.Sprintf(`
		{
			"id": "%s.%s",
			"classId": "%s.%s",
			"logo": {
			"sourceUri": {
				"uri": "https://temporalglobalcitizen.s3.us-east-2.amazonaws.com/tgc-logo.webp"
			},
			"contentDescription": {
				"defaultValue": {
				"language": "en-US",
				"value": "LOGO_IMAGE_DESCRIPTION"
				}
			}
			},
			"cardTitle": {
			"defaultValue": {
				"language": "en-US",
				"value": "TEMPORAL GLOBAL CITIZEN"
			}
			},
			"subheader": {
			"defaultValue": {
				"language": "en-US",
				"value": "Planet Defender"
			}
			},
			"header": {
			"defaultValue": {
				"language": "en-US",
				"value": "%s"
			}
			},
			"textModulesData": [
				{
					"id": "level",
					"header": "LEVEL",
					"body": "%s"
				},
				{
					"id": "points",
					"header": "POINTS",
					"body": "%s"
				},
				{
					"id": "time",
					"header": "TIME",
					"body": "%s"
				}
				],
			"imageModulesData": [
				{
					"id": "IMAGE_MODULE_ID",
					"mainImage": {
						"contentDescription": {
							"defaultValue": {
								"value": "Header image for temporal global citizen",
								"language": "en-US"
							}
						},
						"sourceUri": {
							"uri": "https://temporalglobalcitizen.s3.us-east-2.amazonaws.com/tgc-header.png"
						}
					}
				}
			],
			"hexBackgroundColor": "#4285f4",
			"heroImage": {
			"sourceUri": {
				"uri": "%s"
			},
		"contentDescription": {
			"defaultValue": {
				"language": "en-US",
				"value": "Badge for the Global Citizen Planet Defender"
				}
			}
			}
		}
	`, issuerId, objectSuffix, issuerId, classSuffix, userName, level, points, time, heroImageUrl)

	log.Println("JSON for wallet object created")
	if d == nil {
		log.Fatalln("demoGeneric is nil")
	}

	payload := bytes.NewBuffer([]byte(newObject))

	if payload == nil {
		log.Fatalln("payload is nil")
	}

	res, err := d.httpClient.Post(objectUrl, "application/json", payload)

	if err != nil {
		log.Println("Error creating wallet object", err)
		return err
	} else {
		b, _ := io.ReadAll(res.Body)
		log.Printf("Object insert response:\n%s\n", b)
	}

	return nil
}

// [END createObject]

// [START jwtExisting]
// Generate a signed JWT that references an existing pass object.

// When the user opens the "Add to Google Wallet" URL and saves the pass to
// their wallet, the pass objects defined in the JWT are added to the
// user's Google Wallet app. This allows the user to save multiple pass
// objects in one API call.
func (d *demoGeneric) createJwtExistingObjects(issuerId, classSuffix, objectSuffix string) WalletResponse {
	var payload map[string]interface{}
	json.Unmarshal([]byte(fmt.Sprintf(`
	{
		"eventTicketObjects": [{
			"id": "%s.%s",
			"classId": "%s.%s"
		}]
	}
	`, issuerId, objectSuffix, issuerId, classSuffix)), &payload)

	claims := jwt.MapClaims{
		"iss":     d.credentials.Email,
		"aud":     "google",
		"origins": []string{"temporal-global-citizen-server.fly.dev"},
		"typ":     "savetowallet",
		"payload": payload,
	}

	// The service account credentials are used to sign the JWT
	key, err := jwt.ParseRSAPrivateKeyFromPEM(d.credentials.PrivateKey)

	if err == nil {
		token, err := jwt.NewWithClaims(jwt.SigningMethodRS256, claims).SignedString(key)

		if err == nil {
			log.Println("Add to Google Wallet link")
			log.Println("https://pay.google.com/gp/v/save/" + token)

			return WalletResponse{
				Url: "https://pay.google.com/gp/v/save/" + token,
			}
		} else {
			log.Println("Error generating token: ", err)
		}
	} else {
		log.Println("Error generating jwt: ", err)
	}

	return WalletResponse{
		Url: "",
	}

}

// [END jwtExisting]

// [START walletHandler]
// Handles the requests to /wallet.
// Returns the add to wallet URL as response.
func walletHandler(w http.ResponseWriter, r *http.Request) {

	var responseText WalletResponse
	// Set CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")    // Allow any origin
	w.Header().Set("Access-Control-Allow-Methods", "GET") // Allow only GET

	// Parse query parameters
	queryParams := r.URL.Query()

	userName := queryParams.Get("username")
	level := queryParams.Get("level")
	points := queryParams.Get("points")
	time := queryParams.Get("time")

	issuerId := os.Getenv("WALLET_ISSUER_ID")

	if issuerId == "" {
		log.Fatalln("issuerId not found, Check the WALLET_ISSUER_ID env variable")
	}
	classSuffix := "planet_defender"
	objectSuffix := fmt.Sprintf("%s-%s", strings.ReplaceAll(uuid.New().String(), "-", "_"), classSuffix)

	heroImageUrl := ""

	if level == "1" {
		heroImageUrl = "https://temporalglobalcitizen.s3.us-east-2.amazonaws.com/badging_app_planetdefender.png__300x300_subsampling-2.png"
	} else if level == "2" {
		heroImageUrl = "https://temporalglobalcitizen.s3.us-east-2.amazonaws.com/badging_app_planetdefender2.png__300x300_subsampling-2.png"
	} else if level == "3" {
		heroImageUrl = "https://temporalglobalcitizen.s3.us-east-2.amazonaws.com/badging_app_planetdefender3.png__300x300_subsampling-2.png"
	}

	d := demoGeneric{}

	d.auth()

	// Class needs to be created only once
	//d.createClass(issuerId, classSuffix)

	err := d.createObject(issuerId, classSuffix, objectSuffix, userName, level, points, time, heroImageUrl)

	if err == nil {
		responseText = d.createJwtExistingObjects(issuerId, classSuffix, objectSuffix)
	} else {
		log.Println("Error creating wallet object: ", err)
		responseText = WalletResponse{
			Url: "",
		}
	}

	// Set content type as JSON for the response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(responseText)
}

// [END walletHandler]

func main() {
	mux := http.NewServeMux()

	// Registering handlers
	mux.HandleFunc("/score/", scoreHandler)
	mux.HandleFunc("/wallet/", walletHandler)

	// Start the server
	http.ListenAndServe(":8080", mux)
	log.Println("Server started at port :8080")
}
