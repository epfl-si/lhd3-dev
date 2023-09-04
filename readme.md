# Guide d'utilisation de `just` pour lancer l'environnement de développement LHDv3

## Prérequis

Pour utiliser ce fichier de script zx, vous aurez besoin de :

1. Node.js et npm : Node.js est une plateforme logicielle libre en JavaScript orientée vers les applications réseau. npm est le gestionnaire de paquets officiel de Node.js.

2. `zx` : `zx` est un outil pour écrire des scripts shell plus facilement avec JavaScript. Vous pouvez l'installer globalement avec la commande `npm install -g zx`.

3. Docker : Docker est un logiciel libre permettant de lancer des applications dans des conteneurs logiciels.

4. git : git est un logiciel de gestion de versions décentralisé.

5. keybase : Keybase est une application de clé publique pour le chiffrement de messages, le partage de fichiers et la gestion des groupes.

6. yarn : Yarn est un gestionnaire de paquets pour le JavaScript.

## Guide d'installation

### Lancement de l'environnement de développement

Vous pouvez utiliser la commande suivante :

```bash
./just
```

Si tout se passe bien, le front-end sera alors disponible à l'adresse http://localhost:3000/

### Commandes disponibles

- **run** : Cette commande clone les dépôts git, installe les dépendances et démarre les serveurs.

- **frontend** : Cette commande clone les dépôts git, installe les dépendances et démarre uniquement le serveur frontal (frontend).

- **backend** : Cette commande clone les dépôts git, installe les dépendances et démarre uniquement le serveur backend.

- **auth** : Cette commande clone les dépôts git, installe les dépendances et démarre uniquement le serveur d'authentification.

- **clean** : Cette commande arrête et supprime les conteneurs démarrés par Keycloak.

- **purge** : Cette commande supprime le volume docker `keycloak_mariadb` utilisé par Keycloak.

- **unclone** : Cette commande supprime les dépôts clonés.

- **help** : Cette commande affiche un message d'aide avec la liste des commandes disponibles et leurs descriptions.

- **version** : Cette commande affiche la version du script.

Pour utiliser une commande spécifique, vous pouvez lancer le script avec la commande souhaitée comme argument, par exemple :

```bash
./just run
```

## Support

Si vous rencontrez des problèmes avec l'utilisation du script `just`, vous pouvez créer un ticket sur le dépôt du projet ou contacter l'équipe de développement.

---

**Note :** Ce guide suppose que vous utilisez une distribution Linux. Si vous utilisez un système d'exploitation différent, certaines commandes peuvent varier. Veuillez consulter la documentation de votre système d'exploitation pour plus d'informations.
