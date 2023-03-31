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
