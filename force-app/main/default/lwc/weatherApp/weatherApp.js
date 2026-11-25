import { LightningElement } from 'lwc';
const API_KEY='08729d23c1d6c779cbe2205cc89dba2a'
export default class WeatherApp extends LightningElement {
//CONTINUE FRON 05:40
    cityName=''
    loadingText=''
    isError=false

    get loadingClasses(){
        return this.isError ? 'error-msg':'success-msg'
    }
    searchHandler(event){
        this.cityName=event.target.value;
    }
    submitHandler(event){
        event.preventDefault();
        this.fetchData();
    }

    fetchData(){
        this.isError=false
        this.loadingText='Featching weather details...'
        console.log("City Name", this.cityName);

        const URL=`https://api.openweathermap.org/data/2.5/weather?q=${this.cityName}&units=metric&appid=${API_KEY}`
    fetch(URL).then(res=>res.json()).then(result=>{
        console.log(JSON.stringify(result))
        this.weatherDetails(result);
        //this.loadingText=''
    }).catch((error)=>{
        console.error(error);
        this.loadingText='Something went wrong'
        this.isError=true
    })
    }


    weatherDetails(info){
        if(info.cod==="404"){
            this.isError=true
            this.loadingText=`${this.cityName} isn't a valid city name`
        }
        else{
            this.loadingText=''
        }
    }
}