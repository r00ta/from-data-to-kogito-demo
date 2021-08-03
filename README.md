# The Intelligent Decisions journey with DMN and PMML

This repository contains an end to end demonstration that starts with some data, trains a machine learning model and deploys it with Kogito. 

## Requirements

The following tools must be installed on the system: 

- Docker >= 20.10.3
- Docker-compose >= 1.25.2
- Java >= 11
- Maven >= 3.6.3
- R >= 3.6.3

The following R packages must be installed: `pmml`, `randomForest`. 

## Step 1 - Generation of the training set

Generate the training set using the script `generate_dataset.R`

```bash
Rscript generate_dataset.R
```

A file `dataset.csv` will be created under the current directory. 

## Step 2 - train the random forest model

Train and export the PMML model using the script `train.R`

```bash
Rscript train.R
```

A file `risk_rf.pmml` will be created under the current directory.

## Step 3 - create a DMN model that adds some logic to the machine learning model

Start the business central container with 

```bash
docker run -it -p8080:8080 --rm jboss/business-central-workbench-showcase:7.51.0.Final
```

Follow the next instructions: 
- Open `http://localhost:8080/business-central/kie-wb.jsp` with your browser. 
- Login with `admin:admin`.
- Add a new namespace `mySpace` and a new project `myMortgage`. 
- Click `import asset` and select the pmml model you created in the previous step. When it is opened, replace the pmml version from `4.4` to `4.2`. Save and download the model. 
- Add another asset with the file `myMortgage.dmn` and open it. Click on the `Included Models` section and select the `risk_rf` pmml model, then open the `Risk Score Model` bkm function and set the `risk_rf` model and inputs. Save and download the model

## Step 4 - Create the kogito application 

Create a new quarkus kogito application with 

```bash
mvn io.quarkus:quarkus-maven-plugin:2.0.3.Final:create \
    -DprojectGroupId=org.acme \
    -DprojectArtifactId=kogito-quickstart \
    -Dextensions="kogito" \
    -DnoExamples
cd kogito-quickstart
``` 

and add the following dependencies in the `pom.xml` file

```bash
    <!-- PMML -->
    <dependency>
      <groupId>org.kie.kogito</groupId>
      <artifactId>kogito-addons-quarkus-tracing-decision</artifactId>
    </dependency>
    <dependency>
      <groupId>org.kie.kogito</groupId>
      <artifactId>kogito-pmml</artifactId>
    </dependency>
    <dependency>
      <groupId>org.kie</groupId>
      <artifactId>kie-dmn-jpmml</artifactId>
      <version>7.55.0.Final</version>
    </dependency>
    <dependency>
      <groupId>org.jpmml</groupId>
      <artifactId>pmml-evaluator</artifactId>
      <version>1.5.15</version>
    </dependency>
    <dependency>
      <groupId>org.jpmml</groupId>
      <artifactId>pmml-evaluator-extension</artifactId>
      <version>1.5.15</version>
    </dependency>
    <dependency>
      <groupId>io.quarkus</groupId>
      <artifactId>quarkus-smallrye-openapi</artifactId>
    </dependency>
```

Add the following property in the `application.properties` file so to get the nice swagger-ui

```properties
quarkus.swagger-ui.always-include=true
```

and copy the `myMortgage.dmn` and `risk_rf.pmml` files under the `resources` folder of the project.

Package the application with 

```bash
mvn clean package -DskipTests
```

and build the docker image with 

```bash
docker build -f src/main/docker/Dockerfile.jvm -t quay.io/jrota/pmml-kogito:1.0 .
```

## Step 5 - Deploy the kogito application with the trustyAI infra

Clone the `kogito-examples` repository and checkout the release branch `1.8.x`

```bash
git clone https://github.com/kiegroup/kogito-examples.git
git checkout 1.8.x
```

open the file `kogito-examples/trusty-demonstration/docker-compose/docker-compose.yaml` and replace the `kogito-app` image with `quay.io/jrota/pmml-kogito:1.0`. 

Stop the business central container so to free the `8080` port. 
Start docker-compose with 

```bash
docker-compose -f kogito-examples/trusty-demonstration/docker-compose/docker-compose.yaml up
```

Copy the generated grafana dashboards to the `docker-compose/grafana` folder

```bash
cp target/classes/META-INF/resources/monitoring/dashboards/* kogito-examples/trusty-demonstration/docker-compose/grafana/provisioning/dashboards/
```

## Step 6 - execute some requests and check the trusty console

Open the kogito application swagger-ui at `localhost:8080/q/swagger-ui` and send a POST request to the endpoint `myMortgage` with the following payload

```json
{
  "Finantial Situation": {
    "MonthlySalary": 2000,
    "TotalAsset": 10000
  },
  "Mortgage Request": {
    "TotalRequired": 100000,
    "NumberInstallments": 100
  },
  "Applicant": {
    "First Name": "Jacopo",
    "Last Name": "Rota",
    "Age": 29,
    "Email": "jrota@redhat.com"
  }
}
```

Check the trusty audit console at `localhost:1338` and play with it!
