# Bereitstellen einer Anwendung mit mehreren Containern auf OpenShift

# Überprüfen des Gerüsts einer Vorlage (TEMPLATE)

$ oc get templates -n openshift

# Im Folgenden wird eine YAML-Vorlagendefinition gezeigt

$ oc get template mysql-persistent -n openshift -o yaml

# Container erstellen Anhand YAML Tempate 

$ oc create -f todo-template.yaml

# Die Vorlage wird standardmäßig für das aktuelle Projekt erstellt, 
# es sei denn, Sie geben mithilfe der -n-Option ein anderes Projekt 
# an (siehe folgendes Beispiel):

$oc create -f todo-template.yaml -n openshift

# WICHTIG:
#Jede Vorlage, die unter dem openshift-Namespace (OpenShift-Projekt) erstellt
#wurde, ist in der Web Console unter dem Dialogfeld verfügbar, auf das über das
#Menüelement Catalog --> Developer Catalog zugegriffen werden kann.


# PARAMETER
# Templates definieren eine Reihe von Parametern, denen Werte zugewiesen sind. 
# OpenShift-Ressourcen, die in der Vorlage definiert sind, können die zugehörigen 
# Konfigurationswerte durch Verweis auf die benannten Parameter abrufen.
# Parameter können beim Bearbeiten der Template ersetzt werden.
# Parameter Werte werden mit oc process oder durch OpenShift der Parameterkonfiguration 
# entsprechend festgelegt 

# Auflisten template Parameter (Es gibt 2 Möglichkeiten): <describe>

# Möglichkeit 1:
$ oc describe template mysql-persistent -n openshift

# Möglichkeit 2:
$ oc process --parameters mysql-persistent -n openshift

# Bearbeiten eines TEMPLATES über die Befehlszeilenschnittstelle
$ oc process -f <filename>  (json oder yaml datei)

# Ausgabe der Ressourcesliste in YAML Format
$ oc process -o yaml -f <filename>  

# Alternativ können Vorlagen über das aktuelle Projekt oder 
# das openshift-Projekt verarbeitet werden:
$ oc process <uploaded-template-name>


# oc process kann auch an eine Datei umgeleitet werden:
$ oc process -o yaml -f filename > myapp.yaml

# Um einen Parameter des Templates zu überschreiben, verwenden Sie die 
# Option -p, gefolgt von einem <name>=<value>-Paar. S. Beispiel unten:

$ oc process -o yaml -f mysql.yaml \
 -p MYSQL_USER=dev -p MYSQL_PASSWORD=$P4SSD -p MYSQL_DATABASE=bank \
 -p VOLUME_CAPACITY=10Gi > mysqlProcessed.yaml

# Erstellen Sie die Anwendung unter Verwendung der generierten YAML-Ressourcendefinitionsdatei:
$ oc create -f mysqlProcessed.yaml

# Es besteht auch die Möglichkeit, die Vorlage mithilfe einer UNIX-Pipe 
# zu verarbeiten und die Anwendung zu erstellen, ohne eine Ressourcendefinitionsdatei zu speichern:
$ oc process -f mysql.yaml \
 -p MYSQL_USER=dev -p MYSQL_PASSWORD=$P4SSD -p MYSQL_DATABASE=bank \
 -p VOLUME_CAPACITY=10Gi | oc create -f -

# Zum Verwenden einer Vorlage im openshift-Projekt, um eine Anwendung in Ihrem Projekt zu
# erstellen, exportieren Sie zunächst die Vorlage:

$ oc get template mysql-persistent -o yaml -n openshift > mysql-persistent-template.yaml

# Identifizieren Sie als Nächstes geeignete Werte für die Template-parameter, 
# und verarbeiten Sie das Template:

$ oc process -f mysql-persistent-template.yaml \
 -p MYSQL_USER=dev -p MYSQL_PASSWORD=$P4SSD -p MYSQL_DATABASE=bank \
 -p VOLUME_CAPACITY=10Gi | oc create -f -

# Sie können auch zwei Schrägstriche (>//) verwenden, um den Namespace als Teil des
# TemplateNamens bereitzustellen:
$ oc process openshift//mysql-persistent \
 -p MYSQL_USER=dev -p MYSQL_PASSWORD=$P4SSD -p MYSQL_DATABASE=bank \
 -p VOLUME_CAPACITY=10Gi | oc create -f -

# Alternativ können Sie eine Anwendung mithilfe des Befehls oc new-app erstellen, indem Sie den
# TemplateNamen als das Optionsargument --template weiterleiten:
$ oc new-app --template=mysql-persistent \
 -p MYSQL_USER=dev -p MYSQL_PASSWORD=$P4SSD -p MYSQL_DATABASE=bank \
 -p VOLUME_CAPACITY=10Gi \
 --as-deployment-config

### Konfigurieren des persistenten Storages für OpenShift-Anwendungen (PV)
#OpenShift Container Platform verwaltet persistenten Storage als eine Reihe clusterweiter Poolressourcen. 
#Um dem Cluster eine Storage-Ressource hinzuzufügen, erstellt ein OpenShift- Administrator ein 
#PersistentVolume-Objekt, das die erforderlichen Metadaten für die Storage-Ressource definiert. 
#Die Metadaten beschreiben, wie der Cluster auf den Storage zugreift, sowie andere Speicherattribute wie Kapazität oder Durchsatz.

#Führen Sie den Befehl [oc get pv] aus, um die PersistentVolume-Objekte in einem Cluster aufzulisten:
$ oc get pv

# Führen Sie den Befehl oc get mit der Option -o yaml aus, um die YAML-Definition für ein
# bestimmtes PersistentVolume anzuzeigen:
$ oc get pv pv0001 -o yaml

# Führen Sie den Befehl oc create aus, um einem Cluster weitere PersistentVolume-Objekte hinzuzufügen:
$ oc create -f pv0002.yaml

### Anfordern von persistenten Volumes (PVC)
#Wenn eine Anwendung Storage benötigt, erstellen Sie ein PersistentVolumeClaim-Objekt
#(PVC), um eine dedizierte Storage-Ressource aus dem Clusterpool anzufordern. 

#Die PVC definiert Storage-Anforderungen für die Anwendungen, beispielsweise die Kapazität oder
#der Durchsatz. Führen Sie den Befehl oc create aus, um die PVC zu erstellen:
$ oc create -f pvc.yaml

#Führen Sie den Befehl oc get pvc aus, um die PVCs in einem Projekt aufzulisten:
$ oc get pvc

#Um das permanente Volume in einem Anwendungs-Pod zu verwenden definieren Sie
#eine Volume-Bereitstellung für einen Container, der auf das 
#PersistentVolumeClaim-Objekt verweist.

###START pvc.yaml###

apiVersion: "v1"
kind: "Pod"
metadata:
  name: "myapp"
  labels:
    name: "myapp"
spec:
  containers:
    - name: "myapp"
       image: openshift/myapp
      ports:
        - containerPort: 80
	      name: "http-server"
      volumeMounts:
        - mountPath: "/var/www/html"
          name: "pvol"  #Dieser Abschnitt deklariert, dass das pvol-Volume unter /var/www/html im Container-Dateisystem eingebunden wird. 
  volumes:
    - name: "pvol"      #Dieser Abschnitt definiert das pvol-Volume. 
      persistentVolumeClaim:
        claimName: "myapp" #Das pvol (Volume) verweist auf die myapp (PVC).
						   #Wenn OpenShift ein verfügbares persistentes Volume
						   #der myapp-PVC zuordnet, verweist dass pvol-Volume
						   #auf dieses zugeordnete Volumen.

### END -pvc.yaml###

#Konfigurieren von persistentem Storage mit Templates
#Templates werden häufig verwendet, um die Erstellung von Anwendungen zu vereinfachen, 
#die persistenten Storage erfordern. Da viele dieses Templates als suffix "persistent" haben....
#die auflistung ist mit grep sehr einfach:

$ oc get templates -n openshift | grep persistent


######### START  myapp-persistent-template.yaml #################
apiVersion: template.openshift.io/v1
kind: Template
labels:
  template: myapp-persistent-template
metadata:
  name: myapp-persistent
  namespace: openshift
objects:
  - apiVersion: v1
    kind: PersistentVolumeClaim  ### das Template definiert ein object PersistentVolumeClaim
    metadata:
      name: ${APP_NAME}
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
		requests:
		  storage: ${VOLUME_CAPACITY}

- apiVersion: v1
  kind: DeploymentConfig        ### .. und ein object DeploymentConfig.... Beide Obj haben mane dem Wert des Parameters APP_NAME
  metadata:
    name: ${APP_NAME}
  spec:
    replicas: 1
    selector:
      name: ${APP_NAME}
    strategy:
      type: Recreate
    template:
      metadata:
        labels:
          name: ${APP_NAME}
      spec:
        containers:
        - image: 'openshift/myapp'
          name: myapp
          volumeMounts:
          - mountPath: /var/lib/myapp/data
            name: ${APP_NAME}-data
        volumes:
        - name: ${APP_NAME}-data
          persistentVolumeClaim:
            claimName: ${APP_NAME}
parameters:
- description: The name for the myapp application.
  displayName: Application Name
  name: APP_NAME
  required: true
  value: myapp
- description: Volume space available for data, e.g. 512Mi, 2Gi.
  displayName: Volume Capacity
  name: VOLUME_CAPACITY
  required: true
  value: 1Gi

######### ENDE  myapp-persistent-template.yaml #################

#Mit dieser Vorlage müssen Sie nur die Parameter APP_NAME und VOLUME_CAPACITY angeben,
#um die myapp-Anwendung mit persistentem Storage bereitzustellen:

$ oc create myapp-template.yaml
template.template.openshift.io/myapp-persistent created

$ oc process myapp-persistent -p APP_NAME=myapp-dev -p VOLUME_CAPACITY=1Gi | oc create -f -
deploymentconfig/myapp created
persistentvolumeclaim/myapp created

























