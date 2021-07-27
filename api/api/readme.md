## Requirements

To install the required modules using pip:

> python3 -m pip install -r requirements.txt

Then, run the API:

> ./app.py

or:

> python3 app.py

which will start the service at `http://localhost:5000/`.

## Cert in Java

In Ubuntu 18.04

```bash
sudo keytool -importcert -file [cert file] -alias [alias] -keystore /etc/ssl/certs/java/cacerts
```

From [stackoverflow](https://stackoverflow.com/a/36427118).

## CORS

For apache using TLS (https), add this to the VirtualHost section:

```
 <IfModule mod_headers.c>
  Header set Access-Control-Allow-Origin "*"
 </IfModule>
```

From [here](https://enable-cors.org/server_apache.html).

## Acknowledgements

This service is based on some code from:

 * OpenRefine [Reconciliation Service API](https://github.com/OpenRefine/OpenRefine/wiki/Reconciliation-Service-API)
 * [AAT-reconcile](https://github.com/mphilli/AAT-reconcile): for reconciling against terms of the Art & Architecture Thesaurus (AAT)

## License

Available under the Apache 2.0 license. Please read the [license](LICENSE) file for details. 
