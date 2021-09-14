for i in $(kind get clusters); do
    echo "Shutting down cluster $i"
    kind delete cluster --name $i
done
