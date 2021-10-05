scratch_alias=$1
dev_hub_alias=$2

if [[ -z "$scratch_alias" ]]
then
	echo "Specify scratch alias as the first parameter."
	exit 1
fi

if [[ -z "$dev_hub_alias" ]]
then
	echo "Specify dev hub alias as the second parameter."
	exit 1
fi

echo
echo "Authorizing the dev hub..."
echo "Please login to your DevHub org."
sfdx force:auth:web:login -a "$dev_hub_alias"

echo
echo "Creating scratch..."
sfdx force:org:create -f ./config/project-scratch-def.json -a "$scratch_alias" -v "$dev_hub_alias"

echo
echo "Deploying to $scratch_alias..."
sfdx force:source:push -u "$scratch_alias"

echo
echo "Assigning permissions..."
sfdx force:user:permset:assign -n TriggerHelperUser -u "$scratch_alias"

echo
sfdx force:org:open -u "$scratch_alias"

rm debug.log
