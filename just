#!/usr/bin/env -S npm exec --yes --package=zx@latest zx --

const gitRepositories = [
	{ git: 'git@github.com:epfl-si/lhd.frontend.git', subdir: 'frontend' },
	{ git: 'git@github.com:epfl-si/lhd.graphql.git', subdir: 'backend' },
];

await parseCmdLineDoThingsAndCleanup();

function help() {
	echo(
		chalk.blue(`
Usage: just [command]

Commands:
  run      Clone git repositories, install dependencies, start servers.
  unclone  Remove cloned repositories.

Options:
  --help
  --version

Examples:
  just run OR just
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
	const mail_cae_to = lhdTestfile.email.cae_to;
	const mail_cae_cc = lhdTestfile.email.cae_cc;
	const mail_cosec_bcc = lhdTestfile.email.cosec_bcc;

	if (! await fs.exists('./backend/.env')) {
		await fs.writeFile(
			'./backend/.env',
			`LHD_DB_URL=mysql://lhd_test_app:${lhdTestDbPassword}@localhost:33006/lhd_test
			LHD_API_PASSWORD=${lhdImapPassword}
			LHD_ENCRYPTION_KEY=${lhdEncryptionKey}
			API_EPFL_CH_URL=api.epfl.ch
			CRISTAL_URL=cristal-test.epfl.ch
			HAZARD_DOCUMENT_FOLDER=hazards/
			DOCUMENTS_PATH=../LHD_documents/upload
			OIDC_BASE_URL=https://login.microsoftonline.com/f6c2556a-c4fb-4ab1-a2c7-9e220df11c43/v2.0/
			OIDC_CLIENT_ID=2c822adc-1365-4b59-931f-64cde59e7d20
			SNOW_TOKEN=DEV
			CATALYSE_TOKEN=DEV
			SMTP_HOST=mail.epfl.ch
			SMTP_PORT=587
			SMTP_USER=lhd@epfl.ch
			CAE_TO=${mail_cae_to}
			CAE_CC=${mail_cae_cc}
			COSEC_BCC=${mail_cosec_bcc}
			APP_BASE_PATH=http://localhost:3000
			HAZARD_TYPES_TO_EMAIL_AFTER_UPDATE=Laser,Biological
			ENVIRONMENT=DEV
			CATALYSE_EMAIL=service_catalyse@epfl.ch
			ALLOWED_GROUPS=LHD_acces_AppGrpU,LHD_acces_lecture_AppGrpU,LHD_acces_admin_AppGrpU,LHD_acces_cosec_AppGrpU
			ADMIN_GROUP=LHD_acces_admin_AppGrpU
			LHD_GROUP=LHD_acces_lecture_AppGrpU
			COSEC_GROUP=LHD_acces_cosec_AppGrpU`
		);
	}
}

async function writeBackendDotEnvForDebug () {
	const lhdTestfile = YAML.parse(
		await keybase_fs_read('/keybase/team/epfl_lhd/secrets_test.yml')
	);
	const lhdImapPassword = lhdTestfile.imap.password;
	const lhdEncryptionKey = lhdTestfile.lhd_encryption_key;
	const mail_cae_to = lhdTestfile.email.cae_to;
	const mail_cae_cc = lhdTestfile.email.cae_cc;
	const mail_cosec_bcc = lhdTestfile.email.cosec_bcc;

	if (! await fs.exists('./backend/.env')) {
		await fs.writeFile(
			'./backend/.env',
			`LHD_DB_URL=mysql://root:ROOT@localhost:3307/lhd_test
			LHD_API_PASSWORD=${lhdImapPassword}
			LHD_ENCRYPTION_KEY=${lhdEncryptionKey}
			API_EPFL_CH_URL=api-preprod.epfl.ch
			CRISTAL_URL=cristal-test.epfl.ch
			HAZARD_DOCUMENT_FOLDER=hazards/
			DOCUMENTS_PATH=../LHD_documents/upload
			OIDC_BASE_URL=https://login.microsoftonline.com/f6c2556a-c4fb-4ab1-a2c7-9e220df11c43/v2.0/
			OIDC_CLIENT_ID=2c822adc-1365-4b59-931f-64cde59e7d20
			SNOW_TOKEN=DEV
			CATALYSE_TOKEN=DEV
			SMTP_HOST=mail.epfl.ch
			SMTP_PORT=587
			SMTP_USER=lhd@epfl.ch
			CAE_TO=${mail_cae_to}
			CAE_CC=${mail_cae_cc}
			COSEC_BCC=${mail_cosec_bcc}
			APP_BASE_PATH=http://localhost:3000
			HAZARD_TYPES_TO_EMAIL_AFTER_UPDATE=Laser,Biological
			ENVIRONMENT=DEV
			CATALYSE_EMAIL=service_catalyse@epfl.ch
			ADMIN_GROUP=LHD_acces_admin
			COSEC_GROUP=LHD_acces_cosec
			ALLOWED_GROUPS=LHD_acces_AppGrpU,LHD_acces_lecture_AppGrpU,LHD_acces_admin_AppGrpU,LHD_acces_cosec_AppGrpU
			ADMIN_GROUP=LHD_acces_admin_AppGrpU
			LHD_GROUP=LHD_acces_lecture_AppGrpU
			COSEC_GROUP=LHD_acces_cosec_AppGrpU`
		);
	}
}

async function run() {
	await gitCloneAll();
	await $`cd frontend && yarn`;
	await $`cd backend && yarn && yarn codegen`;
	await writeBackendDotEnv ();
	await $`npx --package concurrently@latest -y concurrently --kill-others-on-fail --names "frontend,backend" "cd frontend && yarn start" "cd backend && yarn start"`;
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

async function runDebug() {
	await gitCloneAll();
	await $`cd frontend && yarn`;
	await $`cd backend && yarn && yarn codegen`;
	await $`cd ../LHD && docker compose up -d db`;
	await writeBackendDotEnvForDebug ();
	await $`npx --package concurrently@latest -y concurrently --kill-others-on-fail --names "frontend,backend" "cd frontend && yarn start"`;
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
	} else if (argv._[0] === 'pull') {
		argv._.shift();
		await gitPullAll(...argv._);
	} else if (argv._[0] === 'debug') {
		argv._.shift();
		await runDebug(...argv._);
	} else if (argv._[0] === 'unclone') {
		argv._.shift();
		await unclone(...argv._);
	}
}
