#!/usr/bin/env -S npm exec --yes --package=zx@latest zx --

const gitRepositories = [
	{ git: 'git@github.com:epfl-si/lhd.frontend.git', subdir: 'frontend' },
	{ git: 'git@github.com:epfl-si/lhd.graphql.git', subdir: 'backend' },
	{ git: 'git@github.com:epfl-si/epfl-elements-react.git', subdir: 'epfl-elements-react' },
];

await parseCmdLineDoThingsAndCleanup();

function help() {
	echo(
		chalk.blue(`
Usage: just [command]

Commands:
  run      Clone git repositories, install dependencies, start servers.
  clean    Stop and remove containers started by keycloak compose.
  purge    Remove the keycloak_mariadb docker volume used by keycloak.
  unclone  Remove cloned repositories.

Options:
  --help
  --version

Examples:
  just run OR just
  just clean
  just purge
  just unclone
  `)
	);
}

function version() {
	echo(chalk.blue(`just v0.0.1`));
}

async function unclone() {
	for (const { subdir } of gitRepositories) {
		let isClean = false;
		try {
			await $`cd ${subdir}; git status`;
			isClean = true;
			await $`rm -rf ${subdir}`;
		} catch (e) {
			if (!isClean) {
				throw new Error(`${subdir} is not clean: ${e.stderr}`);
			}
		}
	}
}

async function gitCloneAll() {
	for (const toClone of gitRepositories) {
		const { subdir, git } = toClone;
		if (!(await fs.exists(subdir))) {
			await $`git clone ${git} ${subdir}`;
		}
	}
}

async function gitPullAll() {
	await $`git pull --rebase --autostash`;
	for (const toClone of gitRepositories) {
		const { subdir, git } = toClone;
		await $`cd ${subdir}; git pull --rebase --autostash`;
	}
}

async function keybase_fs_read(path) {
	const p = await $`keybase fs read ${path}`.quiet();
	return p.stdout;
}

async function writeBackendDotEnv () {
	const lhdTestfile = YAML.parse(
		await keybase_fs_read('/keybase/team/epfl_lhd/secrets_test.yml')
	);
	const lhdTestDbPassword = lhdTestfile.mysql.lhd_app.password;
	const lhdImapPassword = lhdTestfile.imap.password;
	const lhdEncryptionKey = lhdTestfile.lhd_encryption_key;
	const lhdTestAdmDbPassword = lhdTestfile.mysql.lhd_admin.password;

	if (! await fs.exists('./backend/.env')) {
		await fs.writeFile(
			'./backend/.env',
			`LHD_DB_URL=mysql://lhd_test_app:${lhdTestDbPassword}@localhost:33006/lhd_test
			ALLOWED_GROUPS=LHD_acces,LHD_acces_lecture,LHD_acces_admin,LHD_acces_cosec
			LHD_API_PASSWORD=${lhdImapPassword}
			LHD_ENCRYPTION_KEY=${lhdEncryptionKey}
			API_EPFL_CH_URL=api.epfl.ch
			CRISTAL_URL=cristal-test.epfl.ch
			HAZARD_DOCUMENT_FOLDER=hazards/
			DOCUMENTS_PATH=../LHD_documents/upload
            OIDC_BASE_URL=http://localhost:8080/realms/LHD
            REACT_CLIENT_ID=LHDv3`
		);
	}
}

async function writeBackendDotEnvForDebug () {
	const lhdTestfile = YAML.parse(
		await keybase_fs_read('/keybase/team/epfl_lhd/secrets_test.yml')
	);
	const lhdImapPassword = lhdTestfile.imap.password;
	const lhdEncryptionKey = lhdTestfile.lhd_encryption_key;

	if (! await fs.exists('./backend/.env')) {
		await fs.writeFile(
			'./backend/.env',
			`LHD_DB_URL=mysql://root:ROOT@localhost:3307/lhd_test
		ALLOWED_GROUPS=LHD_acces,LHD_acces_lecture,LHD_acces_admin,LHD_acces_cosec
		LHD_API_PASSWORD=${lhdImapPassword}
		LHD_ENCRYPTION_KEY=${lhdEncryptionKey}
		API_EPFL_CH_URL=api-preprod.epfl.ch
		CRISTAL_URL=cristal-test.epfl.ch
		HAZARD_DOCUMENT_FOLDER=hazards/
		DOCUMENTS_PATH=../LHD_documents/upload
		OIDC_BASE_URL=http://localhost:8080/realms/LHD
		REACT_CLIENT_ID=LHDv3`
		);
	}
}

async function run() {
	await gitCloneAll();
	await $`cd keycloak && docker compose up -d`;
	await $`cd frontend && yarn`;
	await $`cd backend && yarn && yarn codegen`;
	await writeBackendDotEnv ();
	await $`npx --package concurrently@latest -y concurrently --kill-others-on-fail --names "frontend,backend,keycloak" "cd frontend && yarn start" "cd backend && yarn start" "cd keycloak && docker compose logs -f keycloak"`;
}

async function runFrontend() {
	await gitCloneAll();
	await $`cd frontend && yarn`;
	await $`npx --package concurrently@latest -y concurrently --kill-others-on-fail --names "frontend" "cd frontend && yarn start"`;
}

async function runBackend() {
	await gitCloneAll();
	await $`cd backend && yarn`;
	await writeBackendDotEnv ();
	await $`npx --package concurrently@latest -y concurrently --kill-others-on-fail --names "backend" "cd backend && yarn start"`;
}

async function runAuth() {
	await gitCloneAll();
	await $`cd keycloak && docker compose up -d`;
	await $`npx --package concurrently@latest -y concurrently --kill-others-on-fail --names "keycloak" "cd keycloak && docker compose logs -f keycloak"`;
}

async function runDebug() {
	await gitCloneAll();
	await $`cd keycloak && docker compose up -d`;
	await $`cd frontend && yarn`;
	await $`cd backend && yarn && yarn codegen`;
	await $`cd ../LHD && docker compose up -d db`;
	await writeBackendDotEnvForDebug ();
	await $`npx --package concurrently@latest -y concurrently --kill-others-on-fail --names "frontend,backend,keycloak" "cd frontend && yarn start" "cd keycloak && docker compose logs -f keycloak"`;
}

async function clean() {
	await $`cd keycloak && docker compose down`;
}

async function purge() {
	await clean();
	await $`docker volume rm keycloak_mariadb`;
}

async function parseCmdLineDoThingsAndCleanup() {
	if (!argv._[0]) {
		argv._ = ['run'];
	}
	if (argv.help || argv._[0] === 'help') {
		argv._.shift();
		help(...argv._);
	} else if (argv.version || argv._[0] === 'version') {
		argv._.shift();
		version(...argv._);
	} else if (argv._[0] === 'run') {
		argv._.shift();
		await run(...argv._);
	} else if (argv._[0] === 'frontend') {
		argv._.shift();
		await runFrontend(...argv._);
	} else if (argv._[0] === 'backend') {
		argv._.shift();
		await runBackend(...argv._);
	} else if (argv._[0] === 'auth') {
		argv._.shift();
		await runAuth(...argv._);
	} else if (argv._[0] === 'pull') {
		argv._.shift();
		await gitPullAll(...argv._);
	} else if (argv._[0] === 'debug') {
		argv._.shift();
		await runDebug(...argv._);
	} else if (argv._[0] === 'clean') {
		argv._.shift();
		await clean(...argv._);
	} else if (argv._[0] === 'purge') {
		argv._.shift();
		await purge(...argv._);
	} else if (argv._[0] === 'unclone') {
		argv._.shift();
		await unclone(...argv._);
	}
}
