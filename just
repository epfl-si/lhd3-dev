#!/usr/bin/env -S npm exec --yes --package=zx@latest zx --

const gitRepositories = [
	{ git: 'git@gitlab.epfl.ch:lhd/lh3.frontend.git', subdir: 'frontend' },
	{ git: 'git@github.com:epfl-si/lhd.graphql.git', subdir: 'backend' },
];

console.log(argv._); // XXX
await parseCmdLineDoThingsAndCleanup();

function help() {
	echo(chalk.blue('Ça gaze ?'));
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

async function keybase_fs_read(path) {
	const p = await $`keybase fs read ${path}`.quiet();
	return p.stdout;
}

async function run() {
	// TODO: improve.
	await gitCloneAll();
	await $`yarn`;
	await $`cd keycloak && docker compose up -d`;
	await $`cd frontend && yarn`;
	await $`cd backend && yarn`;
	// TODO: Write .env here.
	const lhdTestDbPassword = YAML.parse(
		await keybase_fs_read('/keybase/team/epfl_lhd/secrets_test.yml')
	).mysql.lhd_v2.password;
	await fs.writeFile(
		'./backend/.env',
		`
LHD_DB_URL=mysql://lhd_admin:${lhdTestDbPassword}@localhost:33006/SST_lhd
ALLOWED_GROUPS=lhd_acces_lecture
`
	);
	await $`npx --package concurrently@latest -y concurrently --kill-others-on-fail --names "frontend,backend,keycloak" "cd frontend && yarn start" "cd backend && yarn start" "cd keycloak && docker compose logs -f keycloak"`;
}

async function clean() {
	// TODO: improve.
	await unclone();
}

async function parseCmdLineDoThingsAndCleanup() {
	if (!argv._[0]) {
		argv._ = ['run'];
	}
	if (argv.help || argv._[0] === 'help') {
		argv._.shift();
		help(...argv._);
	} else if (argv._[0] === 'run') {
		argv._.shift();
		await run(...argv._);
	} else if (argv._[0] === 'clean') {
		argv._.shift();
		await clean(...argv._);
	}
}
